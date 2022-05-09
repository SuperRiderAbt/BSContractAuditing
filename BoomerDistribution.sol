// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access//Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface BoomR {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract BoomerDistribution is Context, Ownable, ReentrancyGuard {
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    address private _braddress;
    uint256 private _shares;

    mapping(uint256 => uint256) private _released;

    BoomR public Boomr;

    constructor(uint256 maxids, address braddress) payable {
        require(maxids > 0, "RetirementFund: no ids");
        require(
            braddress != address(0),
            "RetirementFund: account is the zero address"
        );
        _shares = 1;
        _totalShares = maxids;
        Boomr = BoomR(braddress);
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function shares() public pure returns (uint256) {
        return 1;
    }

    function released(uint256 index) public view returns (uint256) {
        return _released[index];
    }

    function _pendingPayment(uint256 totalReceived, uint256 alreadyReleased)
        private
        view
        returns (uint256)
    {
        return
            SafeMath.sub(
                SafeMath.div(
                    (SafeMath.mul(totalReceived, _shares)),
                    _totalShares
                ),
                alreadyReleased
            );
    }

    //Emergency Withdrawl
    function EMwithdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function multiRelease(uint256[] memory id, address payable account)
        public
        virtual
        nonReentrant
    {
        require(
            account == msg.sender,
            "RetirementFund: Caller Account Doesnt Match Supplied Account."
        );
        require(id.length > 0, "RetirementFund: Id Length Invalid");
        require(id.length < 101, "RetirementFund: Limit 100 Tokens");
        //Loop For ID Check
        uint256 totalID = id.length;
        uint256 idChecked = 0;
        uint256 ucount = 0;
        for (uint256 i = 0; i < id.length; i++) {
            ucount = Boomr.ownerOf(id[i]) == msg.sender
                ? uint256(1)
                : uint256(0);
            idChecked = idChecked + ucount;
        }

        require(
            totalID == idChecked,
            "RetirementFund: Caller does not own the token being claimed for."
        );

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = 0;
        uint256 pay = 0;
        //Loop For Payment
        for (uint256 i = 0; i < id.length; i++) {
            pay = _pendingPayment(totalReceived, released(id[i]));

            payment = payment + pay;
            _released[id[i]] += pay;
        }

        require(payment != 0, "RetirementFund: account is not due payment");

        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    ///Custom Stuff

    function updateBRID(address _bridaddr) public onlyOwner {
        Boomr = BoomR(_bridaddr);
    }

    function mymultiPAYOUT(uint256[] memory id) public view returns (uint256) {
        //Loop For ID Check
        require(id.length < 101, "RetirementFund: Limit 100 Tokens");
        uint256 totalID = id.length;
        uint256 idChecked = 0;
        uint256 ucount = 0;
        for (uint256 i = 0; i < id.length; i++) {
            ucount = Boomr.ownerOf(id[i]) == msg.sender
                ? uint256(1)
                : uint256(0);
            idChecked = idChecked + ucount;
        }

        require(
            totalID == idChecked,
            "RetirementFund: Caller does not own the token being claimed for."
        );

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = 0;
        uint256 pay = 0;
        //Loop For Payment
        for (uint256 i = 0; i < id.length; i++) {
            pay = _pendingPayment(totalReceived, released(id[i]));

            payment = payment + pay;
        }

        return payment;
    }

  


}
