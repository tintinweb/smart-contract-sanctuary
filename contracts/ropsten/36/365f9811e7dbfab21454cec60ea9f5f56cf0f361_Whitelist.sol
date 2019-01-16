pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor(address _owner) public {
        owner = _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Whitelist is Ownable {
    mapping(address => bool) internal investorMap;

    /**
    * event for investor approval logging
    * @param investor approved investor
    */
    event Approved(address indexed investor);

    /**
    * event for investor disapproval logging
    * @param investor disapproved investor
    */
    event Disapproved(address indexed investor);

    constructor(address _owner) 
        public 
        Ownable(_owner) 
    {
        
    }

    /** @param _investor the address of investor to be checked
      * @return true if investor is approved
      */
    function isInvestorApproved(address _investor) external view returns (bool) {
        require(_investor != address(0));
        return investorMap[_investor];
    }

    /** @dev approve an investor
      * @param toApprove investor to be approved
      */
    function approveInvestor(address toApprove) external onlyOwner {
        investorMap[toApprove] = true;
        emit Approved(toApprove);
    }

    /** @dev approve investors in bulk
      * @param toApprove array of investors to be approved
      */
    function approveInvestorsInBulk(address[] toApprove) external onlyOwner {
        for (uint i = 0; i < toApprove.length; i++) {
            investorMap[toApprove[i]] = true;
            emit Approved(toApprove[i]);
        }
    }

    /** @dev disapprove an investor
      * @param toDisapprove investor to be disapproved
      */
    function disapproveInvestor(address toDisapprove) external onlyOwner {
        delete investorMap[toDisapprove];
        emit Disapproved(toDisapprove);
    }

    /** @dev disapprove investors in bulk
      * @param toDisapprove array of investors to be disapproved
      */
    function disapproveInvestorsInBulk(address[] toDisapprove) external onlyOwner {
        for (uint i = 0; i < toDisapprove.length; i++) {
            delete investorMap[toDisapprove[i]];
            emit Disapproved(toDisapprove[i]);
        }
    }
}