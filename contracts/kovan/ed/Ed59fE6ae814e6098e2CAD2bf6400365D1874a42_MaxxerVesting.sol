pragma solidity ^0.5.3;

/**
* @title ERC223Interface
* @dev ERC223 Contract Interface
*/
contract ERC223Interface {
    function balanceOf(address who)public view returns (uint);
    function transfer(address to, uint value)public returns (bool success);
    function transfer(address to, uint value, bytes memory data)public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
}

/// @title Interface for the contract that will work with ERC223 tokens.
interface ERC223ReceivingContract { 
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction data.
     */
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

contract MaxxerVesting is ERC223ReceivingContract {
    address public token;

    struct LockBoxStruct {
        address beneficiary;
        uint balance;
        uint releaseTime;
    }
    // This could be a mapping by address, but these numbered lockBoxes support possibility of multiple tranches per address
    LockBoxStruct[] public lockBoxStructs; 
    
    event LogLockBoxDeposit(address sender, uint amount, uint releaseTime);   
    event LogLockBoxWithdrawal(address receiver, uint amount);
    event Withdraw(address _to, uint _value);

    /**
     * @param _token token that will be received by vesting
     */
    constructor (address _token) public {
        token = _token;
    }

    /**
     * @dev Function to receive ERC223 tokens. Receives tokens once.
     *   Checks that transfered amount is exactly as planned (100 000 000 DGTX)
     * @param _value Number of transfered tokens in 10**(decimal)th
     */
    function tokenFallback(address, uint _value, bytes calldata) external {
        require(msg.sender == token);
        uint releaseTime= now + (60*5); 
        LockBoxStruct memory l;

        l.beneficiary = msg.sender;
        l.balance = _value;
        l.releaseTime = releaseTime;

        lockBoxStructs.push(l);

        emit LogLockBoxDeposit(msg.sender, _value, releaseTime);
    }

    function withdraw(uint lockBoxNumber) public returns(bool success) {
        //  if (now < FIRST_UNLOCK) {
        //     return TOTAL_TOKENS;  
        // }

        LockBoxStruct storage l = lockBoxStructs[lockBoxNumber];
        require(l.beneficiary == msg.sender);
        require(l.releaseTime <= now);
        uint amount = l.balance;
        l.balance = 0;
        emit LogLockBoxWithdrawal(msg.sender, amount);
        require(ERC223Interface(token).transfer(msg.sender, amount));
        return true;
    }
}