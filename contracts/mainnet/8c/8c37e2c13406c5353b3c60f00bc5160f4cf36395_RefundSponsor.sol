/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

contract RefundSponsor {

    address public refundSponsor;
    address public sponsoredContract;
    bool public isPaused;
    uint256 public flushNonce;

    mapping (bytes32 => uint256) public refundAmount;
    mapping (address => uint256) public sponsoredAmount;

    event RefundIssued(
        address refundedTo,
        uint256 amount
    );
    
    event RemainTransferred(
        address transferTo,
        uint256 amount
    );

    event SponsoredContribution(
        address sponsor,
        uint256 amount
    );

    modifier onlySponsor() {
        require(
            msg.sender == refundSponsor,
            'RefundSponsor: not a sponsor'
        );
        _;
    }

    receive()
        external
        payable
    {
        sponsoredAmount[msg.sender] += msg.value;
        emit SponsoredContribution(
            msg.sender,
            msg.value
        );
    }

    constructor() {
        refundSponsor = msg.sender;
    }


    function setSponsoredContract(address _s)
        onlySponsor
        external
    {
        sponsoredContract = _s;
    }

    function addGasRefund(address _a, uint256 _g)
        external
    {
        if (msg.sender == sponsoredContract && isPaused == false) {
            refundAmount[getHash(_a)] += _g;
        }
    }

    function setGasRefund(address _a, uint256 _g)
        external
        onlySponsor
    {
        refundAmount[getHash(_a)] = _g;
    }

    function requestGasRefund()
        external
    {
        require(
            isPaused == false,
            'RefundSponsor: refunds paused'
        );

        bytes32 sender = getHash(msg.sender);

        require(
            refundAmount[sender] > 0,
            'RefundSponsor: nothing to refund'
        );

        uint256 amount = getRefundAmount(msg.sender);
        refundAmount[sender] = 0;

        msg.sender.transfer(amount);

        emit RefundIssued(
            msg.sender,
            amount
        );
    }

    function myRefundAmount()
        external
        view
        returns (uint256)
    {
        return getRefundAmount(msg.sender);
    }

    function getRefundAmount(address x)
        public
        view
        returns (uint256)
    {
        return refundAmount[getHash(x)];
    }

    function getHash(address x)
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(x, flushNonce)
        );
    }

    function pause()
        external
        onlySponsor
    {
        isPaused = true;
    }

    function resume()
        external
        onlySponsor
    {
        isPaused = false;
    }

    function flush()
        external
        onlySponsor
    {
        flushNonce += 1;
    }
    
    function transferRemainingSponsoredAmount(uint _amount)
        external
        payable
        onlySponsor
        returns (uint256 amount)
    {
        amount = (_amount > 0) ?
                            _amount:
                            address(this).balance;

        (bool success, ) = refundSponsor.call{ value: amount }("Remaining Sponsored Amount");

        require(success, "tx failed");

        emit RemainTransferred(
            msg.sender,
            amount
        );
    }
}