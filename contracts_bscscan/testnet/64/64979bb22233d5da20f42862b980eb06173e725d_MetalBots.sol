/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

abstract contract Ownable {
    address private _owner = msg.sender;    

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

abstract contract Pausable is Ownable {    
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused = false;    

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function pause() public whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

interface IBEP20 {
  function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

interface IBEP165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IBEP721Receiver {
    function onBEP721Received(address operator, address from, uint256 tokenId, bytes calldata data ) external returns (bytes4);
}

abstract contract BEP165 is IBEP165 {    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBEP165).interfaceId;
    }
}

interface IBEP721 is IBEP165 {  
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
	event OrderCreated(uint256 tokenId, uint128 price);
	event OrderModified(uint256 tokenId, uint256 newPrice);
	event OrderCancelled(uint256 tokenId);
	event OrderCompleted(uint256 tokenId);
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
	function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract MetalBots is Pausable, BEP165, IBEP721 {
    string private _name = "MetalBots";
    string private _symbol = "MBOT";
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;	
	
	IBEP20 private _marketplaceToken;
	uint256 private _marketplaceTax = 3;
	struct RobotSale { address owner; uint128 price; uint256 startedAt; }
	mapping (uint256 => RobotSale) private _robotsForSale;		
	
	function setMarketplaceTax(uint256 newTax) public onlyOwner {
		_marketplaceTax = newTax;
	}

    function supportsInterface(bytes4 interfaceId) public view virtual override(BEP165, IBEP165) returns (bool) {
        return
            interfaceId == type(IBEP721).interfaceId ||
            super.supportsInterface(interfaceId);
    }	

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "BEP721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "BEP721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = MetalBots.ownerOf(tokenId);
        require(to != owner, "BEP721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "BEP721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "BEP721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "BEP721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
	
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {        
        require(_isApprovedOrOwner(msg.sender, tokenId), "BEP721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "BEP721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }
    
    function safeMint(address to, uint256 tokenId) public whenNotPaused onlyOwner{
        _mint(to, tokenId);
        require(_checkOnBEP721Received(address(0), to, tokenId, ""), "BEP721: transfer to non BEP721Receiver implementer");
    }
    
    function burn(uint256 tokenId) public whenNotPaused {
        _burn(tokenId);
    }
	
	function getOrder(uint256 tokenId) public view returns (address, uint128, uint256) {
		require(_exists(tokenId), "BEP721Metadata: price set of nonexistent token");
		RobotSale memory robotSale = _robotsForSale[tokenId];
		require(robotSale.owner != address(0), "BEP721: token is not for sale");
		return (robotSale.owner, robotSale.price, robotSale.startedAt);
	}

    function getOrderPrice(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "BEP721Metadata: price query for nonexistent token");
        RobotSale memory robotSale = _robotsForSale[tokenId];
		require(robotSale.owner != address(0), "BEP721: price query of token sale that does not exist");
		
        return robotSale.price;
    }		
	
	function createOrder(uint256 tokenId, uint128 price) public whenNotPaused {
        require(_exists(tokenId), "BEP721Metadata: sale of nonexistent token");        
		address owner = MetalBots.ownerOf(tokenId);
        require(owner == msg.sender, "BEP721: token sale that does not own");		
        RobotSale memory robotSale = _robotsForSale[tokenId];
		require(robotSale.owner == address(0), "BEP721: token already on sell ");
		require(price > 0, "BEP721: price need be more than zero");		
		
		_approve(address(this), tokenId);				
		robotSale.owner = msg.sender;
		robotSale.price = price;
		robotSale.startedAt = block.timestamp;
        _robotsForSale[tokenId] = robotSale;
        
		emit OrderCreated(tokenId, price);
    }
    
	function setOrderPrice(uint256 tokenId, uint128 newPrice) public whenNotPaused {
        require(_exists(tokenId), "BEP721Metadata: price set of nonexistent token");		
        RobotSale memory robotSale = _robotsForSale[tokenId];
        require(robotSale.owner != address(0), "BEP721Metadata: price set of token sale that does not exist");
		require(_isOwnerOfToken(tokenId), "price set of token sale that does not own");		
		require(_isOwnerOfSale(tokenId), "BEP721: price set of token sale that does not own");
			
        _robotsForSale[tokenId].price = newPrice;
		emit OrderModified(tokenId, newPrice);
    }
	
	function deleteOrder(uint256 tokenId) public whenNotPaused {
		require(_isOwnerOfToken(tokenId) && _isOwnerOfSale(tokenId), "BEP721: delete token sale that does not own");		
		_approve(address(0), tokenId);
		delete _robotsForSale[tokenId];
		emit OrderCancelled(tokenId);
	}
	
	function executeOrder(uint256 tokenId) public payable whenNotPaused {		
		require(getApproved(tokenId) == address(this) || _isApprovedOrOwner(msg.sender, tokenId), "buyer is not authorized to manage the token");
		address tokenSeller = MetalBots.ownerOf(tokenId);
		require(msg.sender != address(0) && msg.sender != tokenSeller, "BEP721: buyer can not be the seller");		
		RobotSale memory robotSale = _robotsForSale[tokenId];
		require(msg.value >= robotSale.price, "BEP721: sale price is higher than bid");
		require(tokenSeller == robotSale.owner, "BEP721: owner of token is not the seller");
		
		delete _robotsForSale[tokenId];
		
		uint256 marketplaceTax = _marketplaceTax;
		uint256 finalOrderPrice = msg.value;
		
		unchecked {
            marketplaceTax = (_marketplaceTax * msg.value / 100);
			finalOrderPrice = msg.value - marketplaceTax;
        }
		
		payable(owner()).transfer(marketplaceTax);
		payable(tokenSeller).transfer(finalOrderPrice);
		//require(_marketplaceToken.transferFrom(tokenSeller, owner(), marketplaceTax), "BEP20: error in payment of marketplace tax");
		//require(_marketplaceToken.transferFrom(msg.sender, tokenSeller, finalOrderPrice), "BEP20: error in transfer sale amount to the seller");
		
		_safeTransfer(tokenSeller, msg.sender, tokenId, "");
		
		emit OrderCompleted(tokenId);
	}
	
	function _isOwnerOfSale(uint256 tokenId) internal view returns (bool) {
        return _robotsForSale[tokenId].owner == msg.sender;
    }
	
	function _isOwnerOfToken(uint256 tokenId) internal view returns (bool) {
		return MetalBots.ownerOf(tokenId) == msg.sender;
	}	

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnBEP721Received(from, to, tokenId, data), "BEP721: transfer to non BEP721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "BEP721: operator query for nonexistent token");
        address owner = MetalBots.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "BEP721: mint to the zero address");
        require(!_exists(tokenId), "BEP721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        require(_exists(tokenId), "BEP721: operator query for nonexistent token");
        address owner = MetalBots.ownerOf(tokenId);
        require(owner == msg.sender, "BEP721Burnable: caller is not owner nor approved");

        _approve(address(0), tokenId);

		delete _robotsForSale[tokenId];

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual whenNotPaused {
        require(MetalBots.ownerOf(tokenId) == from, "BEP721: transfer of token that is not own");
        require(to != address(0), "BEP721: transfer to the zero address");
		
		delete _robotsForSale[tokenId];

        _approve(address(0), tokenId);
		_operatorApprovals[from][address(0)];

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(MetalBots.ownerOf(tokenId), to, tokenId);
    }
	
	function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkOnBEP721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (_isContract(to)) {
            try IBEP721Receiver(to).onBEP721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IBEP721Receiver.onBEP721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("BEP721: transfer to non BEP721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}