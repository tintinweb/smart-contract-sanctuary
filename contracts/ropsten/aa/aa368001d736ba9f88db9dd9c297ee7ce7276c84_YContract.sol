pragma solidity ^0.4.11;

contract Administration {
    mapping (address => bool) public admins;

    constructor() public {
        admins[msg.sender] = true;
    }

    function isAdmin(address _addr) public view returns(bool) {
        if (_addr == address(0)) {
            return false;
        }
        return admins[_addr];
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin != address(0) && !isAdmin(_newAdmin)) {
            admins[_newAdmin] = true;
        }
    }

    function removeAdmin(address _removedAdmin) external onlyAdmin {
        if (isAdmin(_removedAdmin)) {
            delete admins[_removedAdmin];
        }
    }
}

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

contract YContractBase is Administration {
    event Released(uint256 _tokenId);

    struct Ticket {
        uint32 day;
        uint8 ticketType;
    }

    Ticket[] public tickets;
    address[] public tidToOwner;
    mapping (address => uint256) public balances;
    mapping (uint256 => bool) public approveToEveryone;

    /// @dev Add new ticket and returns token ID.
    function _addTicket(address _owner, uint32 _day, uint8 _type) internal returns (uint256) {
        require(_owner != address(0));

        uint256 ticketId = tickets.push(Ticket(_day, _type)) - 1;
        tidToOwner.push(_owner);
        balances[_owner]++;
        return ticketId;
    }

    /// @dev Release ticket without checking ownership.
    function _release(uint256 _tid) internal {
        approveToEveryone[_tid] = true;
        emit Released(_tid);
    }

    function release(uint256 _tid) external {
        require(msg.sender == tidToOwner[_tid]);
        _release(_tid);
    }
    
    function ownedTicketIdList(address _owner) external view returns (uint256[]) {
        uint[] memory result = new uint[](balances[_owner]);
        uint counter = 0;
        for (uint i = 0; i < tickets.length; i++) {
           if (tidToOwner[i] == _owner) {
            result[counter] = i;
            counter++;
          }
        }
        return result;    
    }
}

contract YContractERC721 is YContractBase, ERC721 {
    mapping (uint256 => address) public approveTo;

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return tidToOwner[_tokenId];
    }

    /// @dev Transfer token. Check shall be done before call it.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        if (_from == _to) {
            return;
        }
        tidToOwner[_tokenId] = _to;
        balances[_from]--;
        balances[_to]++;
        delete approveTo[_tokenId];
        delete approveToEveryone[_tokenId];

        emit Transfer(_from, _to, _tokenId);
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(msg.sender == tidToOwner[_tokenId]);
        require(_to != address(0));

        _transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) public {
        require(msg.sender == tidToOwner[_tokenId]);
        require(_to != address(0));

        approveTo[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(approveToEveryone[_tokenId] || approveTo[_tokenId] == msg.sender);
        _transfer(tidToOwner[_tokenId], msg.sender, _tokenId);
    }
}

contract YContract is YContractERC721 {
    function issue(uint32 _day, uint8 _type, uint _num_of_issue, bool _isApproveToEveryone) external onlyAdmin {
        uint i;
        for (i = 0; i < _num_of_issue; i++) {
            uint256 tid = _addTicket(msg.sender, _day, _type);
            if (_isApproveToEveryone) {
                _release(tid);
            }
        }
    }

    function forceRelease(uint256 _tid) external onlyAdmin {
        require(tidToOwner[_tid] != address(0));
        _release(_tid);
    }

    function _consume(address _owner, uint256 _tokenId) internal {
        tidToOwner[_tokenId] = 0;
        balances[_owner]--;
        delete approveTo[_tokenId];
        delete approveToEveryone[_tokenId];
    }

    function consume(uint256 _tid) external {
        address owner = tidToOwner[_tid];
        require(msg.sender == owner);

        _consume(owner, _tid);
    }

    function forceConsume(uint256 _tid) external onlyAdmin {
        address owner = tidToOwner[_tid];
        require(owner != address(0));

        _consume(owner, _tid);
    }

    function forceTransfer(address _to, uint256 _tid) external onlyAdmin {
        require(_to != address(0));

        address owner = tidToOwner[_tid];
        require(owner != address(0));

        _transfer(owner, _to, _tid);
    }
}