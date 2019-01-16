pragma solidity ^0.5.2;

/** @author Egidio Casati - January the 14th 2019 
 *  @title sum and store
 *  @notice this smart contract calculates the sum of two addendums and store it in an array, 
 *  @notice together with the sender addres who sent the transaction, who actually becames the sum&#39;s owner */
contract sumandstore {
    
    /** @notice when a new sum is calculated by a new owner, an event is fired */
    event newSum (uint sumID, uint sumResult, address sumOwner);
    
    /** @notice sum is a data structure modeling a single sum */ 
    struct sum {
        uint add1;
        uint add2;
        uint sumResult;
    }
    
    /** @notice sums is an array of sums */
    sum[] public sums;
    
    /** @notice every sum has its owner, i.e. the address that sent the sum transaction request */
    mapping (uint => address) public sumIsOwnedBy;
    
    /** @notice  owner onewd sums is store and updated */
    mapping (address => uint) sumsPerOwnerCount;
    
    /** @notice mapping to resolve what is the sumId ownerd by a particular address */
    mapping (address => uint) addressOwnsSum;

    function _sumThem(uint _add1, uint _add2) internal {
        /** @notice calculates the sum of two addendums, store the result and stores its onwing address;
         *  @notice this function is only for internal use.
         *  @param _add1 first addendum
         *  @param _add2 second addendum
         */
        uint _sumResult = _add1 + _add2;
        uint id = sums.push(sum(_add1, _add2, _sumResult)) - 1;
        sumIsOwnedBy[id] = msg.sender;
        sumsPerOwnerCount[msg.sender]++;
        addressOwnsSum[msg.sender]=id;
        emit newSum(id, _sumResult, msg.sender);
    }
    
    function mySum(uint _add1, uint _add2) public {
        require(sumsPerOwnerCount[msg.sender] == 0);
        _sumThem(_add1, _add2);
    }

    function getSum (address _owner) external view returns (
        uint sumId,
        uint add1, 
        uint add2, 
        uint sumResult) {
            uint _id = addressOwnsSum[_owner];
            sum memory ownerSum = sums[_id];
            return (_id, ownerSum.add1, ownerSum.add2, ownerSum.sumResult);
        }
}