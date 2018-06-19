pragma solidity ^0.4.13;

contract ChooseWHGReturnAddress {
    
    mapping (address => address) returnAddresses;
    uint public endDate;
    
    /// @param _endDate After this time, if `requestReturn()` has not been called 
    /// the upgraded parity multisig will be locked in as the &#39;returnAddr&#39;
    function ChooseWHGReturnAddress(uint _endDate) {
        endDate = _endDate;
    }
    
    /////////////////////////
    //   IMPORTANT
    /////////////////////////
    // @dev The `returnAddr` can be changed only once.
    //  We will send the funds to the chosen address. This is Crypto, if the
    //  address is wrong, your funds could be lost, please, proceed with extreme 
    //  caution and treat this like you are sending all of your funds to this 
    //  address.
    
    /// @notice This function is used to choose an address for returning the funds.
    ///  This function can only be called once, PLEASE READ THE NOTE ABOVE.
    /// @param _returnAddr The address that will receive the recued funds
    function requestReturn(address _returnAddr) {
    
        // After the end date, the newly deployed parity multisig will be 
        //  chosen if no transaction is made.
        require(now <= endDate);

        require(returnAddresses[msg.sender] == 0x0);
        returnAddresses[msg.sender] = _returnAddr;
        ReturnRequested(msg.sender, _returnAddr);
    }
    /// @notice This is a simple getter function that will be used to return the 
    ///  address that the WHG will return the funds to
    /// @param _addr The address of the newly deployed parity multisig
    /// @return address The chosen address that the funds will be returned to
    function getReturnAddress(address _addr) constant returns (address) {
        if (returnAddresses[_addr] == 0x0) {
            return _addr;
        } else {
            return returnAddresses[_addr];
        }
    }
    
    function isReturnRequested(address _addr) constant returns (bool) {
        return returnAddresses[_addr] != 0x0;
    }
    
    event ReturnRequested(address indexed origin, address indexed returnAddress);
}