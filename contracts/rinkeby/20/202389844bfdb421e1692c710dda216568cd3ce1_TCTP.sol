/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract TCTP is Ownable {
     
    mapping(address => uint256) public addressToAmountFunded;
    mapping(bytes32 => uint256) public contract_history;
    address[] public funders;
    uint256 public sale_ammount;

    // OPEN = Accepting FUNDS
    // CLOSED = No longer accepting funds and in a Investment search state
    // ACTIVE = no longer accepting funds and accquired funds invested
    // COMPLETED = no longfer accepting funds and invesmtnet sold, investors can now cash out
    enum FundState {
        OPEN, 
        CLOSED,
        ACTIVE,
        COMPLETED
    }

    FundState public fund_state;

    constructor(){
        fund_state = FundState.CLOSED;
    }
    // state: open fund
    function openFund() public onlyOwner {
        require(fund_state != FundState.OPEN || fund_state != FundState.ACTIVE || fund_state != FundState.COMPLETED, "Not in a state that allows the fund to be open");
        fund_state = FundState.OPEN;
    }

    // state: close fund
    function closeFund() public onlyOwner {
        require(fund_state == FundState.OPEN, "Not in a state that allows the fund to be open");
        fund_state = FundState.CLOSED;
    }

    // state: activate
    function activateFund() public onlyOwner {
        require(fund_state == FundState.CLOSED, "Not in a state that allows the fund to be open");
        fund_state = FundState.ACTIVE;
    }

    // state: completed
    function completeFund() internal {
        require(fund_state == FundState.ACTIVE, "Not in a state that allows the fund to be open");
        fund_state = FundState.COMPLETED;
    }

    // add funds
    function fund() public payable {
        require(fund_state == FundState.OPEN, "Fund is not open");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // clear participants
    function clearParticipants() internal onlyOwner {
        // need better logic to only be able to clear after a certain time period or people collected
        require(fund_state == FundState.COMPLETED, "FUND is not in a completed state");
        for (uint i=0; i< funders.length; i++) {
            delete addressToAmountFunded[funders[i]];
        }
        delete funders;
    }

    // history
    function setSale(uint256 _ammount, bytes32 _txn) public onlyOwner {
        require(fund_state == FundState.ACTIVE, "FUND Not in the correct state");
        contract_history[_txn] = _ammount;
        completeFund();
        sale_ammount = calculateSaleAmmount(_ammount);
    }

    function calculateSaleAmmount(uint256 _ammount) internal pure returns (uint256) {
        return _ammount * 100 * 9;
    }

    // pay out origin wallet 
    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // calculate payout
    function calculatePayout() internal {
        for(uint256 i = 0; i < funders.length; i++) {
            uint256 investedAmount = addressToAmountFunded[funders[i]];
            uint256 newAmmount = (investedAmount / sale_ammount) * sale_ammount;
            addressToAmountFunded[funders[i]] = newAmmount;
        }
    }

    // profit claim
    function payInvestors() public payable onlyOwner {
        calculatePayout();
        for(uint256 i = 0; i < funders.length; i++) {
            payable(funders[i]).transfer(addressToAmountFunded[funders[i]]);
        }
        clearParticipants(); 
    }
}