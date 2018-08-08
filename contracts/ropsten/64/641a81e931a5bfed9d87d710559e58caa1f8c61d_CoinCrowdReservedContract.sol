pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract tokenInterface {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
	string public symbols;
	function originBurn(uint256 _value) public returns(bool);
}
contract TokedoDaicoInterface {
    function sendTokens(address _buyer, uint256 _amount) public returns(bool);
    address public owner;
}

contract AtomaxKyc {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (bytes32 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, bytes32 buyerId, uint maxAmount);

    constructor() internal {
        isKycSigner[0x9787295cdAb28b6640bc7e7db52b447B56b1b1f0] = true; //ATOMAX KYC 1 SIGNER
        isKycSigner[0x3b3f379e49cD95937121567EE696dB6657861FB0] = true; //ATOMAX KYC 2 SIGNER
    }

    // Must be implemented in descending contract to assign tokens to the buyers. Called after the KYC verification is passed
    function releaseTokensTo(address buyer) internal returns(bool);
    
    function buyTokens(bytes32 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s) public payable returns (bool) {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(address _buyerAddress, bytes32 _buyerId, uint256 _maxAmount, uint8 _v, bytes32 _r, bytes32 _s) private returns (bool) {
        // check the signature
        bytes32 hash = hasher ( _buyerAddress,  _buyerId,  _maxAmount );
        address signer = ecrecover(hash, _v, _r, _s);
		
		require( isKycSigner[signer], "isKycSigner[signer]");
        
		uint256 totalPayed = alreadyPayed[_buyerId].add(msg.value);
		require(totalPayed <= _maxAmount);
		alreadyPayed[_buyerId] = totalPayed;
		
		emit KycVerified(signer, _buyerAddress, _buyerId, _maxAmount);
		return releaseTokensTo(_buyerAddress);

    }
    
    function hasher (address _buyerAddress, bytes32 _buyerId, uint256 _maxAmount) public view returns ( bytes32 hash ) {
        hash = keccak256(abi.encodePacked("Atomax authorization:", this, _buyerAddress, _buyerId, _maxAmount));
    }
}

contract CoinCrowdReservedContract is AtomaxKyc {
    using SafeMath for uint256;
    
    tokenInterface public xcc;
    TokedoDaicoInterface public tokenSaleContract;
    
    mapping (address => uint256) public tkd_amount;
    
    constructor(address _xcc, address _tokenSaleAddress) public {
        xcc = tokenInterface(_xcc);
        tokenSaleContract = TokedoDaicoInterface(_tokenSaleAddress);
    } 

    function releaseTokensTo(address _buyer) internal returns(bool) {
        require ( msg.sender == tx.origin, "msg.sender == tx.orgin" );
		
		uint256 xcc_amount = xcc.balanceOf(msg.sender);
		require( xcc_amount > 0, "xcc_amount > 0" );
		
		xcc.originBurn(xcc_amount);
		tokenSaleContract.sendTokens(_buyer, xcc_amount);
		
		if ( msg.value > 0 ) msg.sender.transfer(msg.value);
		
        return true;
    }
    
    modifier onlyTokenSaleOwner() {
        require(msg.sender == tokenSaleContract.owner() );
        _;
    }
    
    function withdrawTokens(address tknAddr, address to, uint256 value) public onlyTokenSaleOwner returns (bool) { //emergency function
        return tokenInterface(tknAddr).transfer(to, value);
    }
    
    function withdraw(address to, uint256 value) public onlyTokenSaleOwner { //emergency function
        to.transfer(value);
    }
}