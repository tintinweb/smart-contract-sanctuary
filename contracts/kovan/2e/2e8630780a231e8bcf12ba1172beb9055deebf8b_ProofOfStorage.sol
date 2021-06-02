// SPDX-License-Identifier: MIT

/*
    Created by DeNet
*/

pragma solidity >=0.4.22 <0.9.0;

import "./owner.sol";
import "./IUserStorage.sol";
import "./IPayments.sol";
import "./BaseMath.sol";


contract CryptoProofs {
    using BaseMath for uint256;
    
    event wrongError(bytes32 wrong_hash);
    
    uint256 public base_difficulty;

    constructor (uint256 _baseDifficulty) {
        base_difficulty = _baseDifficulty;
    }
    
    
    function isValidSign(address _signer, bytes memory message, bytes memory signature) public pure returns(bool){
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length == 65) {
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }
        
        return _signer == ecrecover(sha256(message),v, r, s);
    }
    
    function isValidMerkleTreeProof(bytes32 _root_hash, bytes32[] calldata proof) public pure returns(bool)  {
        bytes32 next_proof = 0;
        for(uint32 i = 0; i < proof.length / 2; i++) {
            next_proof = sha256(abi.encodePacked(proof[i*2], proof[i*2+1]));
            if (proof.length - 1 > i*2+3) {
                if (proof[i*2+2] == next_proof && proof[i*2+3] == next_proof) {
                    return false;
                }
            }
            else if (proof.length - 1 > i*2+2) {
                if (proof[i*2+2] != next_proof) {
                    return false;
                }
            }
        }
        return _root_hash == next_proof;
    }
    
    function isMatchDifficulty(uint256 _proof, uint256 _targetDifficulty) public view  returns(bool){
        if (_proof % base_difficulty < _targetDifficulty) {
            return true;
        }
        return false;
    }
    

    function getBlockNumber() public view returns (uint32) {
        return uint32(block.number);
    } 
    
    function getBlockHash(uint32 _n) public view returns (bytes32) {
        return blockhash(_n);
    }
 
}

contract ProofOfStorage is Ownable, CryptoProofs {
  using BaseMath for uint256;
  
  address public user_storage_address;
  address public payments_address;
  uint256 private max_blocks_after_proof = 100;
  
  constructor(
      address _storage_address,
      address _payments_address,
      uint256 _baseDifficulty
  ) CryptoProofs(_baseDifficulty) {
    user_storage_address = _storage_address;
    payments_address = _payments_address;
  }
  
  
    function sendProof(
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof) public {
        address[2] memory _senders =  [msg.sender,_user_address];
        
        // verify Signature
        require(isValidSign(_user_address, abi.encodePacked(_user_root_hash, uint256(_user_root_hash_nonce)), _user_signature), "wrong signature");
        
        _sendProofFrom(
        _senders,
        _block_number,
        _user_root_hash,
        _user_root_hash_nonce,
        _file,
        merkleProof
        );
    }
    
     function sendProofFrom(
        address _node_address,
        address _user_address,
        uint32 _block_number,
        bytes32 _user_root_hash,
        uint64 _user_root_hash_nonce,
        bytes calldata _user_signature,
        bytes calldata _file,
        bytes32[] calldata merkleProof) public {
            
        address[2] memory _senders =  [_node_address, _user_address];
         // verify Signature
        require(isValidSign(_user_address, abi.encodePacked(_user_root_hash, uint256(_user_root_hash_nonce)), _user_signature), "wrong signature");
        
        _sendProofFrom(
        _senders,
        _block_number,
        _user_root_hash,
        _user_root_hash_nonce,
        _file,
        merkleProof
        );
    }
  
  
  
 
    function _updateRootHash(address _user, address _updater, bytes32 new_hash, uint64 new_nonce) private {
        bytes32  _cur_user_root_hash;
        uint256  _cur_user_root_hash_nonce;
        (_cur_user_root_hash, _cur_user_root_hash_nonce) = getUserRootHash(_user);
        
        require(new_nonce >= _cur_user_root_hash_nonce, "Too old root hash");
        
        // update root hash if it needed
        if (new_hash != _cur_user_root_hash) {
            UpdateLastRootHash(_user, new_hash, new_nonce, _updater);
        }
    }
    
    function verifyFileProof(address _sender, bytes calldata _file, uint32 _block_number, uint256 _blocks_complited) public view returns (bool) {
         bytes32  _file_proof = sha256(abi.encodePacked(_file, _sender, blockhash(_block_number)));
         return isMatchDifficulty(uint(_file_proof), _blocks_complited);
    }

  /*
    _senders[0] = _proofer
    _senders[1] = _user_address 
  */
  
  function _sendProofFrom(
      address[2] memory _senders,
      uint32 _block_number,
      bytes32 _user_root_hash,
      uint64 _user_root_hash_nonce,
      bytes calldata _file,
      bytes32[] calldata merkleProof
  ) private  {
      
      // not need, with using signature checking
      require(_senders[0] != address(0) && _senders[1] != address(0), "address can't be zero");
      
      // warning test function without checking  DigitalSIgnature from User SEnding File
      _updateRootHash(_senders[1], _senders[0], _user_root_hash, _user_root_hash_nonce);
      
      address _token_to_pay;
      uint256 _amount_returns;
      uint256 _blocks_complited;

      bytes32  _file_hash = sha256(_file);
     

      (_token_to_pay, _amount_returns, _blocks_complited) = getUserRewardInfo(_senders[1]);
      
      
      require(_block_number > block.number - max_blocks_after_proof, "Too old proof");
      require(isValidMerkleTreeProof(_user_root_hash, merkleProof), "Wrong merkleProof");
      require(verifyFileProof(_senders[0], _file, _block_number, _blocks_complited ), "Not match difficulty");
      require(_file_hash == merkleProof[0] || _file_hash == merkleProof[1], "not found _file_hash in merkleProof");
      
      takePay(_token_to_pay, _senders[1], _senders[0], _amount_returns);
      UpdateLastBlockNumber(_senders[1], uint32(block.number));
      
      
  }
  
  function setUserPlan(address _token) public {
      IUserStorage _storage = IUserStorage(user_storage_address);
      _storage.SetUserPlan(msg.sender, _token);
  }
  
  
  
  /*
    Returns info about user reward for ProofOfStorage
    
        # Input
            @_user - User Address
        
        # Output
            @_token_ddress - Token Address
            @_amount - Total Token Amount for PoS
            @_cur_block - Last Proof Block
        
  */
    function getUserRewardInfo(address _user) public view returns(address, uint256, uint256 ) {
      
        IPayments _payment = IPayments(payments_address);
        
        IUserStorage _storage = IUserStorage(user_storage_address);
        address _token_pay = _storage.GetUserPayToken(_user);
        uint256 user_balance = _payment.getBalance(_token_pay, _user); 
        
        uint256 _amount_per_block = user_balance / 2102400; // balance / (60 * 60 * 24 * 365) / 15  
        uint32 _cur_block = _storage.GetUserLastBlockNumber(_user);
        uint32 _blocks_complited =  uint32(block.number - _cur_block);
        uint256 amount_returns = _blocks_complited * _amount_per_block;
        
        return (_token_pay, amount_returns, _blocks_complited);
    }
    
    function takePay(address _token, address _from , address _to, uint256 _amount) private {
        IPayments _payment = IPayments(payments_address);
        _payment.localTransferFrom ( _token,  _from,  _to, _amount);
    }

  
    function getUserRootHash(address _user) public view returns (bytes32, uint256) {
        IUserStorage _storage = IUserStorage(user_storage_address);
        return _storage.GetUserRootHash(_user);
    }
  
  
  function UpdateLastBlockNumber(address  _user_address, uint32 _block_number) private {
      IUserStorage  _storage = IUserStorage(user_storage_address);
      _storage.UpdateLastBlockNumber( _user_address, _block_number);
  }
  
  function UpdateLastRootHash(address _user_address, bytes32 _user_root_hash, uint64 _nonce, address _updater) private {
      IUserStorage  _storage = IUserStorage(user_storage_address);
      _storage.UpdateRootHash(_user_address, _user_root_hash, _nonce, _updater);
  }
  
  function makeDeposit(address _token, uint _amount)  public{
      IPayments _payment = IPayments(payments_address);
      _payment.depositToLocal(msg.sender, _token, _amount);
  }
  
  function closeDeposit(address _token) public {
      IPayments _payment = IPayments(payments_address);
      _payment.closeDeposit(msg.sender, _token);
  }
  
  function updateBaseDifficulty(uint256 _new_difficulty) public onlyOwner {
      base_difficulty = _new_difficulty;
  }
  
  function changeSystemAddresses(address _storage_address, address _payments_address) public onlyOwner {
    user_storage_address = _storage_address;
    payments_address = _payments_address;
  }
    
}