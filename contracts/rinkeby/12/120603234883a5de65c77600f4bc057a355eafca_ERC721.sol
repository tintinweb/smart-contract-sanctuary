/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

pragma solidity 0.8.2;

interface NFT {
     
    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function _mint(address _to, string memory _uri) external;

    function approve(address _approved, uint256 _tokenId) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    function setApprovalForAll(address _operator, bool _approved) external;

    function transferFrom(address _from,address _to,uint256 _tokenId) external;

    function Onsell(uint256 amt_, uint256 tokenId_) external;

    function offSell(uint256 tokenId_) external;

    function buyNow(uint256 tokenId_) external payable;
}

contract ERC721 is NFT {
    //state variables
    address deployer;
    uint256 counter;
    string _name;
    string _symbol;

    //Events
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    event OnSell(address indexed _owner, uint256 price, uint256 tokenId);
    event Buy(
        address indexed _oldOwner,
        address indexed _newOwner,
        uint256 _tokenId,
        uint256 _price,
        uint256 _time
    );

    //Structure
    struct Sell {
        uint256 tokenId;
        uint256 price;
        address owner;
        bool status;
    }

    //Mappings
    mapping(uint256 => address)  _owners; // Mapping from token ID to owner address
    mapping(address => uint256)  _balances; // Mapping owner address to token count
    mapping(uint256 => address)  _tokenApprovals; // Mapping from token ID to approved address
    mapping(address => mapping(address => bool))  _operatorApprovals; // Mapping from owner to operator approvals
    mapping(uint256 => Sell)  _onSell; //Mapping for sells
    mapping(uint256 => string) _Uri; //mapping for metadata

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    //Functions
    function balanceOf(address _owner) public view override returns (uint256) {
        // return balance of an address
        require(_owner != address(0), "Address cannot be zero");
        return _balances[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        //return owner address of a token.
        require(_owners[_tokenId] != address(0), "Nonexistent token");
        return _owners[_tokenId];
    }

    function _mint(address _to, string memory _uri) public override {
        // anyone can mint nft
        require(_to != address(0), "ERC721: mint to the zero address");
        counter++;
        _Uri[counter] = _uri;
        _balances[_to] += 1;
        _owners[counter] = _to;
        emit Transfer(address(0), _to, counter);
    }

    function approve(address _approved, uint256 _tokenId) public override {
        //approve another operator for token
        require(
            msg.sender == _owners[_tokenId],
            "You are not Owner of this NFT"
        );
        _tokenApprovals[_tokenId] = _approved;
        _operatorApprovals[msg.sender][_approved] = true;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        //returns approvers address set for that token
        address approval = _tokenApprovals[_tokenId];
        return approval;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        //Tells whether an operator is approved by a given owner.
        return (_operatorApprovals[_owner][_operator] == true) ? true : false;
    }

    function setApprovalForAll(address _operator, bool _approved)
        public
        override
    {
        //Sets or unsets the approval of a given operator
        require(_balances[msg.sender] != 0, "You must hold atleast 1 NFT");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        require(
            msg.sender == _owners[_tokenId] ||
                msg.sender == _tokenApprovals[_tokenId],
            "Caller is not authorized person or owner"
        );
        require(_to != address(0));
        require(_from == _owners[_tokenId], "You are not Owner");
        _tokenApprovals[_tokenId] = address(0);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;
        emit Transfer(msg.sender, _to, _tokenId);
    }

    function Onsell(uint256 amt_, uint256 tokenId_) public override {
        //only owner or approver can put nft on sell
        require(_balances[msg.sender] != 0, "You dont have NFTs");
        require(amt_ != 0, "Oops! don't have enough funds");
        require(
            msg.sender == _owners[tokenId_] ||
                msg.sender == _tokenApprovals[tokenId_],
            "Caller is not authorized person or owner"
        );
        uint256 amt = (amt_ * 1 ether);
        Sell memory sell = Sell(tokenId_, amt, msg.sender, true);
        _onSell[tokenId_] = sell;
        emit OnSell(msg.sender, amt, tokenId_);
    }

    function offSell(uint256 tokenId_) public override {
        //remove nft from sell
        require(_onSell[tokenId_].status == true, "NFT is not for sell");
        _onSell[tokenId_].status = false;
    }

    function buyNow(uint256 tokenId_) public payable override {
        //buy nft
        require(_onSell[tokenId_].status == true, "This NFT is not for sale");
        require(
            msg.sender != _owners[tokenId_] ||
                msg.sender == _tokenApprovals[tokenId_],
            "You are owner of NFT"
        );
        require(
            msg.value == _onSell[tokenId_].price,
            "You have not enough balance to buy"
        );
        address payable owner = payable(address(_owners[tokenId_]));
        owner.transfer(msg.value);
        _tokenApprovals[tokenId_] = address(0);
        _balances[owner] -= 1;
        _balances[msg.sender] += 1;
        _owners[tokenId_] = msg.sender;
        emit Transfer(owner, msg.sender, tokenId_);
        _onSell[tokenId_].status = false;
        emit Buy(
            _owners[tokenId_],
            msg.sender,
            tokenId_,
            msg.value,
            block.timestamp
        );
    }
}