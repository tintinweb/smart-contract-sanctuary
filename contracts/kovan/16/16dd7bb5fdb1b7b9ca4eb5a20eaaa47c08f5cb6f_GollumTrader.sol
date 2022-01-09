/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

pragma solidity 0.6.0;

interface ERC721 {
  function safeTransferFrom(address from,address to,uint256 tokenId) external;
}

interface ERC20 {
  function transferFrom(address src, address dst, uint wad)
        external
        returns (bool);
}


contract GollumTrader {
  mapping(bytes32 => bool) public orderhashes; // keep tracks of orderhashes that are filled or cancelled so they cant be filled again 
  mapping(bytes32 => bool) public offerhashes; // keep tracks of offerhashes that are filled or cancelled so they cant be filled again 
  address payable owner;
  ERC20 wethcontract;
  event Orderfilled(address indexed from,address indexed to, bytes32 indexed id, uint ethamt,address refferer,uint feeamt);
  event Offerfilled(address indexed from,address indexed to, bytes32 indexed id, uint ethamt,uint feeamt);
  event Ordercancelled(bytes32 indexed id);

  constructor ()
        public
  {
    owner = payable(msg.sender);
    address WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    wethcontract = ERC20(WETH);
  }

/// @notice returns eip712domainhash
    function _eip712DomainHash() internal view returns(bytes32 eip712DomainHash) {
        eip712DomainHash = keccak256(
        abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes("GOLLUM.XYZ")),
            keccak256(bytes("1")),
            42,
            address(this)
        )
    );  
    }




// address[4]      _addressArgs, // contractaddress, royaltyaddress ,reffereraddress ,signer
// uint[6]        _uintArgs, //tokenid,ethamt,deadline,feeamt,salt,royaltyamt

  function executeOrderIfSignatureMatch(
    uint8 v,
    bytes32 r,
    bytes32 s,
    address[4] calldata _addressArgs,
    uint[6] calldata _uintArgs
    // address payable signer
  ) external payable {
    require(block.timestamp < _uintArgs[2], "Signed transaction expired");

    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("matchorder(address contractaddress,uint tokenid,uint ethamt,uint deadline,uint feeamt,address signer,uint salt,address royaltyaddress,uint royaltyamt)"),
          _addressArgs[0],
          _uintArgs[0],
          _uintArgs[1],
          _uintArgs[2],
          _uintArgs[3],
          _addressArgs[3],
          _uintArgs[4],
          _addressArgs[1],
          _uintArgs[5]
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _eip712DomainHash(), hashStruct));
    address signaturesigner = ecrecover(hash, v, r, s);
    require(signaturesigner == _addressArgs[3], "invalid signature");
    require(msg.value == _uintArgs[1], "wrong eth amt");
    require(orderhashes[hashStruct]==false,"order filled or cancelled");
    orderhashes[hashStruct]=true; // prevent reentrency and also doesnt allow any order to be filled more then once
    ERC721 nftcontract = ERC721(_addressArgs[0]);
    nftcontract.safeTransferFrom(_addressArgs[3],msg.sender ,_uintArgs[0]); // transfer 
    if (_uintArgs[3]>0){
      owner.transfer(_uintArgs[3]); // fee transfer to owner
    }
    if (_uintArgs[5]>0){ // if royalty has to be paid
     payable(_addressArgs[1]).transfer(_uintArgs[5]); // royalty transfer to royaltyaddress
    }
    payable(_addressArgs[3]).transfer(msg.value-_uintArgs[3]-_uintArgs[5]); // transfer of eth to seller of nft
    emit Orderfilled(_addressArgs[3], msg.sender, hashStruct , _uintArgs[1] , _addressArgs[2] ,_uintArgs[3]);

  }

/// @notice invalidates an offchain order signature so it cant be filled by anyone
/// @param contractaddress nft ERC721 contract address which is being traded
/// @param tokenid nft ERC721 token id
/// @param ethamt amount of weth in wei that the seller gets
/// @param deadline deadline till order is valid
/// @param feeamt fee to be paid to owner of contract
/// @param salt salt for uniqueness of the order


  function cancelOrder(    
    address contractaddress,
    uint256 tokenid,
    uint256 ethamt,
    uint256 deadline,
    uint256 feeamt,
    uint256 salt
) external{
      bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("matchorder(address contractaddress,uint tokenid,uint ethamt,uint deadline,uint feeamt,address signer,uint salt)"),
          contractaddress,
          tokenid,
          ethamt,
          deadline,
          feeamt,
          msg.sender,
          salt
        )
    );
        orderhashes[hashStruct]=true;  // no need to check for signature validation since sender can only invalidate his own order
        emit Ordercancelled(hashStruct);
  }


/// @notice called by seller of ERc721NFT when he sees a signed buy offer of ethamt ETH
/// @param v,r,s EIP712 type signature of signer/buyer
/// @param contractaddress nft ERC721 contract address which is being traded
/// @param tokenid nft ERC721 token id
/// @param ethamt amount of weth in wei that the seller gets
/// @param deadline deadline till order is valid
/// @param feeamt fee to be paid to owner of contract
/// @param signer buyer of nft and signer of v,r,s signature
/// @param salt salt for uniqueness of the order

  function executeOfferIfSignatureMatch(
    uint8 v,
    bytes32 r,
    bytes32 s,
    address contractaddress,
    uint256 tokenid,
    uint256 ethamt,
    uint256 deadline,
    uint256 feeamt,
    address signer,
    uint256 salt
  ) external {
    require(block.timestamp < deadline, "Signed transaction expired");

    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("matchoffer(address contractaddress,uint tokenid,uint ethamt,uint deadline,uint feeamt,address signer,uint salt)"),
          contractaddress,
          tokenid,
          ethamt,
          deadline,
          feeamt,
          signer,
          salt
        )
    );


    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _eip712DomainHash(), hashStruct));
    address signaturesigner = ecrecover(hash, v, r, s);
    require(signaturesigner == signer, "invalid signature");
    require(offerhashes[hashStruct]==false,"order filled or cancelled");
    offerhashes[hashStruct]=true;
    if (feeamt>0){
      require(wethcontract.transferFrom(signer, owner , feeamt),"error in weth transfer");
    }
    require(wethcontract.transferFrom(signer, msg.sender, ethamt-feeamt),"error in weth transfer");
    ERC721 nftcontract = ERC721(contractaddress);
    nftcontract.safeTransferFrom(msg.sender,signer ,tokenid);
    emit Offerfilled(signer, msg.sender, hashStruct , ethamt ,feeamt);
  }



/// @notice invalidates an offchain offer signature so it cant be filled by anyone
/// @param contractaddress nft ERC721 contract address which is being traded
/// @param tokenid nft ERC721 token id
/// @param ethamt amount of weth in wei that the seller gets
/// @param deadline deadline till order is valid
/// @param feeamt fee to be paid to owner of contract
/// @param salt salt for uniqueness of the order

  function cancelOffer(    
    address contractaddress,
    uint256 tokenid,
    uint256 ethamt,
    uint256 deadline,
    uint256 feeamt,
    uint256 salt

) external{
      bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("matchoffer(address contractaddress,uint tokenid,uint ethamt,uint deadline,uint feeamt,address signer,uint salt)"),
          contractaddress,
          tokenid,
          ethamt,
          deadline,
          feeamt,
          msg.sender,
          salt
        )
    );
      offerhashes[hashStruct]=true;  
      emit Ordercancelled(hashStruct);
  }

// returns Keccak256 hash of an order
  function Orderstruct(   
    address contractaddress,
    uint256 tokenid,
    uint256 ethamt,
    uint256 deadline,
    uint256 feeamt,
    address signer,
    uint256 salt
    ) public pure returns (bytes32) {
        return keccak256(
      abi.encode(
          keccak256("matchorder(address contractaddress,uint tokenid,uint ethamt,uint deadline,uint feeamt,address signer,uint salt)"),
          contractaddress,
          tokenid,
          ethamt,
          deadline,
          feeamt,
          signer,
          salt
        )
    );
    }

  // returns Keccak256 hash of an offer
  function Offerstruct(   
    address contractaddress,
    uint256 tokenid,
    uint256 ethamt,
    uint256 deadline,
    uint256 feeamt,
    address signer,
    uint256 salt
    ) public pure returns (bytes32) {
        return keccak256(
      abi.encode(
          keccak256("matchoffer(address contractaddress,uint tokenid,uint ethamt,uint deadline,uint feeamt,address signer,uint salt)"),
          contractaddress,
          tokenid,
          ethamt,
          deadline,
          feeamt,
          signer,
          salt
        )
    );
    }


// ALREADY FILLED OR CANCELLED - 1
// deadline PASSED- 2  EXPIRED
// sign INVALID - 0
// VALID - 3
/// @notice returns status of an order

  function OrderStatus(
    uint8 v,
    bytes32 r,
    bytes32 s,
    address contractaddress,
    uint256 tokenid,
    uint256 ethamt,
    uint256 deadline,
    uint256 feeamt,
    address signer,
    uint256 salt
  ) public view returns (uint256) {
    if (block.timestamp < deadline){
      return 2;
    }
    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("matchorder(address contractaddress,uint tokenid,uint ethamt,uint deadline,uint feeamt,address signer,uint salt)"),
          contractaddress,
          tokenid,
          ethamt,
          deadline,
          feeamt,
          signer,
          salt
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _eip712DomainHash(), hashStruct));
    address signaturesigner = ecrecover(hash, v, r, s);

    if (signaturesigner != signer){
      return 0;
    }
    if (orderhashes[hashStruct]==true){
      return 1;
    }

    return 3;

  }


// ALREADY FILLED OR CANCELLED - 1
// deadline PASSED- 2  EXPIRED
// sign INVALID - 0
// VALID - 3
/// @notice returns status of an order

  function OfferStatus(
    uint8 v,
    bytes32 r,
    bytes32 s,
    address contractaddress,
    uint256 tokenid,
    uint256 ethamt,
    uint256 deadline,
    uint256 feeamt,
    address signer,
    uint256 salt
  ) public view returns (uint256) {
    if (block.timestamp < deadline){
      return 2;
    }
    bytes32 hashStruct = keccak256(
      abi.encode(
          keccak256("matchoffer(address contractaddress,uint tokenid,uint ethamt,uint deadline,uint feeamt,address signer,uint salt)"),
          contractaddress,
          tokenid,
          ethamt,
          deadline,
          feeamt,
          signer,
          salt
        )
    );

    bytes32 hash = keccak256(abi.encodePacked("\x19\x01", _eip712DomainHash(), hashStruct));
    address signaturesigner = ecrecover(hash, v, r, s);

    if (signaturesigner != signer){
      return 0;
    }
    if (offerhashes[hashStruct]==true){
      return 1;
    }

    return 3;

  }



}