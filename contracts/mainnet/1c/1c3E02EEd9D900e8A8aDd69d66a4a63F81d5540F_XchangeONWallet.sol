/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity 0.5.12;

/**
* @author XchangeON.
*/

/**
* @title IERC223Token
* @dev ERC223 Contract Interface
*/
contract IERC223Token {
    function transfer(address _to, uint256 _value) public returns (bool);
    function balanceOf(address who)public view returns (uint);
}

/**
* @title ForwarderContract
* @dev Contract that will forward any incoming Ether & token to wallet
*/
contract ForwarderContract {
    
    address payable public parentAddress;
 
    event ForwarderDeposited(address from, uint value, bytes data);
    event TokensFlushed(address forwarderAddress, uint value, address tokenContractAddress);

    /**
    * @dev Modifier that will execute internal code block only if the sender is the parent address
    */
    modifier onlyParent {
        require(msg.sender == parentAddress);
        _;
    }
    
    /**
    * @dev Create the contract, and sets the destination address to that of the creator
    */
    constructor() public{
        parentAddress = msg.sender;
    }

    /**
    * @dev Default function; Gets called when Ether is deposited, and forwards it to the parent address.
    *      Credit eth to contract creator.
    */
    function() external payable {
        parentAddress.transfer(msg.value);
        emit ForwarderDeposited(msg.sender, msg.value, msg.data);
    }

    /**
    * @dev Execute a token transfer of the full balance from the forwarder contract to the parent address
    * @param _tokenContractAddress the address of the erc20 token contract
    */
    function flushDeposit(address _tokenContractAddress) public onlyParent {
        IERC223Token instance = IERC223Token(_tokenContractAddress);
        uint forwarderBalance = instance.balanceOf(address(this));
        require(forwarderBalance > 0);
        require(instance.transfer(parentAddress, forwarderBalance));
        emit TokensFlushed(address(this), forwarderBalance, _tokenContractAddress);
    }
  
    /**
    * @dev Execute a specified token transfer from the forwarder contract to the parent address.
    * @param _from the address of the erc20 token contract.
    * @param _value the amount of token.
    */
    function flushAmountToken(address _from, uint _value) external{
        require(IERC223Token(_from).transfer(parentAddress, _value), "instance error");
    }

    /**
    * @dev It is possible that funds were sent to this address before the contract was deployed.
    *      We can flush those funds to the parent address.
    */
    function flush() public {
        parentAddress.transfer(address(this).balance);
    }
}

/**
* @title XchangeONWallet
*/
contract XchangeONWallet {
    
    address[] public signers;
    bool public safeMode; 
    uint private forwarderCount;
    uint private lastNounce;
    
    event Deposited(address from, uint value, bytes data);
    event SafeModeActivated(address msgSender);
    event SafeModeInActivated(address msgSender);
    event ForwarderCreated(address forwarderAddress);
    event Transacted(address msgSender, address otherSigner, bytes32 operation, address toAddress, uint value, bytes data);
    event TokensTransfer(address tokenContractAddress, uint value);
    
    /**
    * @dev Modifier that will execute internal code block only if the 
    *      sender is an authorized signer on this wallet
    */
    modifier onlySigner {
        require(validateSigner(msg.sender));
        _;
    }

    /**
    * @dev Set up a simple multi-sig wallet by specifying the signers allowed to be used on this wallet.
    *      2 signers will be required to send a transaction from this wallet.
    *      Note: The sender is NOT automatically added to the list of signers.
    *      Signers CANNOT be changed once they are set
    * @param allowedSigners An array of signers on the wallet
    */
    constructor(address[] memory allowedSigners) public {
        require(allowedSigners.length == 3);
        signers = allowedSigners;
    }

    /**
    * @dev Gets called when a transaction is received without calling a method
    */
    function() external payable {
        if(msg.value > 0){
            emit Deposited(msg.sender, msg.value, msg.data);
        }
    }
    
    /**
    * @dev Determine if an address is a signer on this wallet
    * @param signer address to check
    * @return boolean indicating whether address is signer or not
    */
    function validateSigner(address signer) public view returns (bool) {
        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Irrevocably puts contract into safe mode. When in this mode, 
    *      transactions may only be sent to signing addresses.
    */
    function activateSafeMode() public onlySigner {
        require(!safeMode);
        safeMode = true;
        emit SafeModeActivated(msg.sender);
    }
    
    /**
    * @dev Irrevocably puts out contract into safe mode.
    */ 
    function deactivateSafeMode() public onlySigner {
        require(safeMode);
        safeMode = false;
        emit SafeModeInActivated(msg.sender);
    }
    
    /**
    * @dev Generate a new contract (and also address) that forwards deposite to this contract
    *      returns address of newly created forwarder address
    */
    function generateForwarder() public returns (address) {
        ForwarderContract f = new ForwarderContract();
        forwarderCount += 1;
        emit ForwarderCreated(address(f));
        return(address(f));
    }
    
    /**
    * @dev for return No of forwarder generated. 
    * @return total number of generated forwarder count.
    */
    function totalForwarderCount() public view returns(uint){
        return forwarderCount;
    }
    
    /**
    * @dev Execute a flushDeposit from one of the forwarder addresses.
    * @param forwarderAddress the contract address of the forwarder address to flush the tokens from
    * @param tokenContractAddress the address of the erc20 token contract
    */
    function flushForwarderDeposit(address payable forwarderAddress, address tokenContractAddress) public onlySigner {
        ForwarderContract forwarder = ForwarderContract(forwarderAddress);
        forwarder.flushDeposit(tokenContractAddress);
    }
    
    /**
    * @dev Gets the next available nounce for signing when using executeAndConfirm
    * @return the nounce one higher than the highest currently stored
    */
    function getNonce() public view returns (uint) {
        return lastNounce+1;
    }
    
    /** 
    * @dev generate the hash for transferMultiSigEther
    *      same parameter as transferMultiSigEther
    * @return the hash generated by parameters 
    */
    function generateEtherHash(address toAddress, uint value, bytes memory data, uint expireTime, uint nounce)public pure returns (bytes32){
        return keccak256(abi.encodePacked("ETHER", toAddress, value, data, expireTime, nounce));
    }

    /**
    * @dev Execute a multi-signature transaction from this wallet using 2 signers: 
    *      one from msg.sender and the other from ecrecover.
    *      nonce are numbers starting from 1. They are used to prevent replay 
    *      attacks and may not be repeated.
    * @param toAddress the destination address to send an outgoing transaction
    * @param value the amount in Wei to be sent
    * @param data the data to send to the toAddress when invoking the transaction
    * @param expireTime the number of seconds since 1970 for which this transaction is valid
    * @param nounce the unique nounce obtainable from getNonce
    * @param signature see Data Formats
    */
    function transferMultiSigEther(address payable toAddress, uint value, bytes memory data, uint expireTime, uint nounce, bytes memory signature) public payable onlySigner {
        bytes32 operationHash = keccak256(abi.encodePacked("ETHER", toAddress, value, data, expireTime, nounce));
        address otherSigner = verifyMultiSig(toAddress, operationHash, signature, expireTime, nounce);
        toAddress.transfer(value);
        emit Transacted(msg.sender, otherSigner, operationHash, toAddress, value, data);
    }
    
    /** 
    * @dev generate the hash for transferMultiSigTokens.
    *      same parameter as transferMultiSigTokens.
    * @return the hash generated by parameters 
    */
    function generateTokenHash( address toAddress, uint value, address tokenContractAddress, uint expireTime, uint nounce) public pure returns (bytes32){
        return keccak256(abi.encodePacked("ERC20", toAddress, value, tokenContractAddress, expireTime, nounce));
    }
  
    /**
    * @dev Execute a multi-signature token transfer from this wallet using 2 signers: 
    *      one from msg.sender and the other from ecrecover.
    *      nounce are numbers starting from 1. They are used to prevent replay 
    *      attacks and may not be repeated.
    * @param toAddress the destination address to send an outgoing transaction
    * @param value the amount in tokens to be sent
    * @param tokenContractAddress the address of the erc20 token contract
    * @param expireTime the number of seconds since 1970 for which this transaction is valid
    * @param nounce the unique nounce obtainable from getNonce
    * @param signature see Data Formats
    */
    function transferMultiSigTokens(address toAddress, uint value, address tokenContractAddress, uint expireTime, uint nounce, bytes memory signature) public onlySigner {
        bytes32 operationHash = keccak256(abi.encodePacked("ERC20", toAddress, value, tokenContractAddress, expireTime, nounce));
        verifyMultiSig(toAddress, operationHash, signature, expireTime, nounce);
        IERC223Token instance = IERC223Token(tokenContractAddress);
        require(instance.balanceOf(address(this)) > 0);
        require(instance.transfer(toAddress, value));
        emit TokensTransfer(tokenContractAddress, value);
    }
    
    /**
    * @dev Gets signer's address using ecrecover
    * @param operationHash see Data Formats
    * @param signature see Data Formats
    * @return address recovered from the signature
    */
    function recoverAddressFromSignature(bytes32 operationHash, bytes memory signature) private pure returns (address) {
        require(signature.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27; 
        }
        return ecrecover(operationHash, v, r, s);
    }

    /**
    * @dev Verify that the nonce has not been used before and inserts it. Throws if the nonce was not accepted.
    * @param nounce to insert into array of stored ids
    */
    function validateNonce(uint nounce) private onlySigner {
        require(nounce > lastNounce && nounce <= (lastNounce+1000), "Enter Valid Nounce");
        lastNounce=nounce;
    }

    /** 
    * @dev Do common multisig verification for both eth sends and erc20token transfers
    * @param toAddress the destination address to send an outgoing transaction
    * @param operationHash see Data Formats
    * @param signature see Data Formats
    * @param expireTime the number of seconds since 1970 for which this transaction is valid
    * @param nounce the unique nounce obtainable from getNonce
    * @return address that has created the signature
    */
    function verifyMultiSig(address toAddress, bytes32 operationHash, bytes memory signature, uint expireTime, uint nounce) private returns (address) {

        address otherSigner = recoverAddressFromSignature(operationHash, signature);
        if (safeMode && !validateSigner(toAddress)) {
            revert("safemode error");
        }
        require(validateSigner(otherSigner) && expireTime > now);
        require(otherSigner != msg.sender);
        validateNonce(nounce);
        return otherSigner;
    }
}