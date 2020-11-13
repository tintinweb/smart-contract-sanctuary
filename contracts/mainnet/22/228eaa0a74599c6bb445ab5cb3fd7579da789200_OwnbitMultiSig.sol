pragma solidity ^0.4.21;

// This is the ETH/ERC20 multisig contract for Ownbit.
//
// For 2-of-3 multisig, to authorize a spend, two signtures must be provided by 2 of the 3 owners.
// To generate the message to be signed, provide the destination address and
// spend amount (in wei) to the generateMessageToSignmethod.
// The signatures must be provided as the (v, r, s) hex-encoded coordinates.
// The S coordinate must be 0x00 or 0x01 corresponding to 0x1b and 0x1c, respectively.
// See the test file for example inputs.
//
// WARNING: The generated message is only valid until the next spend is executed.
//          after that, a new message will need to be calculated.
//
//
// INFO: This contract is ERC20 compatible.
// This contract can both receive ETH and ERC20 tokens.
// NFT is not supported
// Add support for DeFi (Compound)

interface Erc20 {
    function approve(address, uint256);

    function transfer(address, uint256);
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

interface CEth {
    function mint() external payable;

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

contract OwnbitMultiSig {
    
    uint constant public MAX_OWNER_COUNT = 9;

  // The N addresses which control the funds in this contract.  The
  // owners of M of these addresses will need to both sign a message
  // allowing the funds in this contract to be spent.
  mapping(address => bool) private isOwner;
  address[] private owners;
  uint private required;

  // The contract nonce is not accessible to the contract so we
  // implement a nonce-like variable for replay protection.
  uint256 private spendNonce = 0;
  
  // An event sent when funds are received.
  event Funded(uint new_balance);
  
  // An event sent when a spend is triggered to the given address.
  event Spent(address to, uint transfer);
  
  // An event sent when a spend is triggered to the given address.
  event SpentErc20(address erc20contract, address to, uint transfer);

  modifier validRequirement(uint ownerCount, uint _required) {
        require (ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required > 0);
        _;
    }
  
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i=0; i<_owners.length; i++) {
            //onwer should be distinct, and non-zero
            if (isOwner[_owners[i]] || _owners[i] == 0) {
                revert();
            }
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }


    // The fallback function for this contract.
    function() public payable {
        emit Funded(address(this).balance);
    }
  
    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners() public constant returns (address[]) {
        return owners;
    }
    
    function getSpendNonce() public constant returns (uint256) {
        return spendNonce;
    }
    
    function getRequired() public constant returns (uint) {
        return required;
    }

  // Generates the message to sign given the output destination address and amount.
  // includes this contract's address and a nonce for replay protection.
  // One option to  independently verify: https://leventozturk.com/engineering/sha3/ and select keccak
  function generateMessageToSign(address erc20Contract, address destination, uint256 value) public constant returns (bytes32) {
    require(destination != address(this));
    //the sequence should match generateMultiSigV2 in JS
    bytes32 message = keccak256(this, erc20Contract, destination, value, spendNonce);
    return message;
  }
  
  function _messageToRecover(address erc20Contract, address destination, uint256 value) private constant returns (bytes32) {
    bytes32 hashedUnsignedMessage = generateMessageToSign(erc20Contract, destination, value);
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return keccak256(prefix,hashedUnsignedMessage);
  }
  
  function spend(address destination, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss) public {
    // This require is handled by generateMessageToSign()
    // require(destination != address(this));
    require(address(this).balance >= value);
    require(_validSignature(0x0000000000000000000000000000000000000000, destination, value, vs, rs, ss));
    spendNonce = spendNonce + 1;
    //transfer will throw if fails
    destination.transfer(value);
    emit Spent(destination, value);
  }
  
  // @erc20contract: the erc20 contract address.
  // @destination: the token or ether receiver address.
  // @value: the token or ether value, in wei or token minimum unit.
  // @vs, rs, ss: the signatures
  function spendERC20(address destination, address erc20contract, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss) public {
    // This require is handled by generateMessageToSign()
    // require(destination != address(this));
    //transfer erc20 token
    //require(ERC20Interface(erc20contract).balanceOf(address(this)) >= value);
    require(_validSignature(erc20contract, destination, value, vs, rs, ss));
    spendNonce = spendNonce + 1;
    // transfer the tokens from the sender to this contract
    Erc20(erc20contract).transfer(destination, value);
    emit SpentErc20(erc20contract, destination, value);
  }


    //cErc20Contract is just like the destination
    function compoundAction(address cErc20Contract, address erc20contract, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss) public {
        CEth ethToken;
        CErc20 erc20Token;
        
        if (erc20contract == 0x0000000000000000000000000000000000000001) {
            require(_validSignature(erc20contract, cErc20Contract, value, vs, rs, ss));
            spendNonce = spendNonce + 1;
            
            //supply ETH
            ethToken = CEth(cErc20Contract);
            ethToken.mint.value(value).gas(250000)();
        } else if (erc20contract == 0x0000000000000000000000000000000000000003) {
            require(_validSignature(erc20contract, cErc20Contract, value, vs, rs, ss));
            spendNonce = spendNonce + 1;
            
            //redeem ETH
            ethToken = CEth(cErc20Contract);
            ethToken.redeem(value);
        } else if (erc20contract == 0x0000000000000000000000000000000000000004) {
            require(_validSignature(erc20contract, cErc20Contract, value, vs, rs, ss));
            spendNonce = spendNonce + 1;
            
            //redeem token
            erc20Token = CErc20(cErc20Contract);
            erc20Token.redeem(value);
        } else if (erc20contract == 0x0000000000000000000000000000000000000005) {
            require(_validSignature(erc20contract, cErc20Contract, value, vs, rs, ss));
            spendNonce = spendNonce + 1;
            
            //redeemUnderlying ETH
            ethToken = CEth(cErc20Contract);
            ethToken.redeemUnderlying(value);
        } else if (erc20contract == 0x0000000000000000000000000000000000000006) {
            require(_validSignature(erc20contract, cErc20Contract, value, vs, rs, ss));
            spendNonce = spendNonce + 1;
            
            //redeemUnderlying token
            erc20Token = CErc20(cErc20Contract);
            erc20Token.redeemUnderlying(value);
        } else {
            //Do not conflict with spendERC20
            require(_validSignature(0x0000000000000000000000000000000000000002, cErc20Contract, value, vs, rs, ss));
            spendNonce = spendNonce + 1;
            
            //supply token
            // Create a reference to the underlying asset contract, like DAI.
            Erc20 underlying = Erc20(erc20contract);
            // Create a reference to the corresponding cToken contract, like cDAI
            erc20Token = CErc20(cErc20Contract);
            // Approve transfer on the ERC20 contract
            underlying.approve(cErc20Contract, value);
            // Mint cTokens
            erc20Token.mint(value);
        } 
    }
    

  // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
  // authorize a spend of this contract's funds to the given
  // destination address.
  function _validSignature(address erc20Contract, address destination, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss) private constant returns (bool) {
    require(vs.length == rs.length);
    require(rs.length == ss.length);
    require(vs.length <= owners.length);
    require(vs.length >= required);
    bytes32 message = _messageToRecover(erc20Contract, destination, value);
    address[] memory addrs = new address[](vs.length);
    for (uint i=0; i<vs.length; i++) {
        //recover the address associated with the public key from elliptic curve signature or return zero on error 
        addrs[i] = ecrecover(message, vs[i]+27, rs[i], ss[i]);
    }
    require(_distinctOwners(addrs));
    return true;
  }
  
  // Confirm the addresses as distinct owners of this contract.
  function _distinctOwners(address[] addrs) private constant returns (bool) {
    if (addrs.length > owners.length) {
        return false;
    }
    for (uint i = 0; i < addrs.length; i++) {
        if (!isOwner[addrs[i]]) {
            return false;
        }
        //address should be distinct
        for (uint j = 0; j < i; j++) {
            if (addrs[i] == addrs[j]) {
                return false;
            }
        }
    }
    return true;
  }
}