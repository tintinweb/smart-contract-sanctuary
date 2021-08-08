// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


interface ERC721Interface {
  event Transfer( address indexed _from, address indexed _to, uint256 _tokenId );

  function balanceOf(address _owner) external view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) external view returns (address _owner);

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract Owned {
    address public owner;

    constructor()  {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}



contract Auction is Owned {
    
    string public name = 'NFT Auction';
    string public detail = 'Auction Detail';
    string public website = 'https://www.domain.com';
    uint256 public time_start;
    uint256 public time_end;
    
    bool ended = false;
    uint256 public price_start = 0;
    uint256 public price_current = 0;

    address public nft_address;
    uint256 public nft_id;

    enum State{On,Off}
    State public status = State.Off;

    uint256 record_id = 0;
    uint256 public record_count = 0;
    
    struct Record{
        uint256 id;
        address addr;
        uint256 amount;
        uint256 time;
    }    

    mapping(uint => Record) records;

    event Bid(address indexed _from, uint256 indexed _amount, uint256  _time, uint256 indexed _index);
    event Refund(address indexed _to, uint256 indexed _amount, uint256 indexed _index);
    event Ended(address indexed _winner, uint256 indexed _amount);
    event EndedFalse(address indexed _winner, address indexed _owner, address indexed _sender);

    modifier checkAuction() {
        require(status == State.Off,"Auction status disable.");
        require(block.timestamp <= time_start,"Start auction in soon.");
        require(block.timestamp >= time_end,"Auction already ended.");
        require(msg.value <= price_current,"There already is a lower bid.");
        _;
    }
    
    modifier checkEnded() {
        require(status == State.Off,"Auction status disable.");
        require(block.timestamp >= time_end,"Auction not yet ended.");
        require(ended == true,"Auction end has already been called.");
        _;
    }

    receive() external payable checkAuction {
        records[record_id] = Record(record_id, msg.sender, msg.value, block.timestamp);
        record_id++;
        record_count = record_id;
        price_current = msg.value;
        emit Bid(msg.sender, msg.value, block.timestamp, record_id);
        if(record_count>1){
            uint256 prev_id = record_id-2;
            
            Record memory payee = records[prev_id];
            address refund = payee.addr;
            payable(refund).transfer(payee.amount);
            emit Refund(payee.addr, payee.amount, prev_id);
        }
    }

    constructor(uint256 _time_start, uint256 _time_end, address _nft_address, uint256 _nft_id)  {

        time_start = _time_start;
        time_end = _time_end;

        nft_address = _nft_address;
        nft_id = _nft_id;
    }

    function AuctionEnd() public checkEnded {
        ERC721Interface instance = ERC721Interface(nft_address);
        require(instance.ownerOf(nft_id) != address(msg.sender),"You can't call AuctionEnd.");

        Record memory winner = records[record_id];

        if(instance.ownerOf(nft_id) == address(msg.sender)){
            ended = true;
            emit Ended( winner.addr, winner.amount );
            instance.transferFrom(msg.sender, winner.addr, nft_id);
        }else{
            emit EndedFalse( winner.addr, instance.ownerOf(nft_id), address(msg.sender) );
        }
    }
    
	function paginateHistory(uint _resultsPerPage, uint _page) external view returns (Record[] memory) {
	  Record[] memory result = new Record[](_resultsPerPage);
	  for(uint i = _resultsPerPage * _page - _resultsPerPage; i < _resultsPerPage * _page; i++ ){
	      result[i] = records[i];
	    } 
	    return result;
	}
    
    
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}