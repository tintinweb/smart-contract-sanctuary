/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
/// SPDX-License-Identifier: GPL-3.0-or-later

library SafeMath { // arithmetic wrapper for unit under/overflow check
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

library Utilities {
	// concat two bytes objects
    function concat(bytes memory a, bytes memory b)
            internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }

    // convert address to bytes
    function toBytes(address x) internal pure returns (bytes memory b) {
		b = new bytes(20);

		for (uint i = 0; i < 20; i++)
			b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
	}

	// convert uint256 to bytes
	function toBytes(uint256 x) internal pure returns (bytes memory b) {
    	b = new bytes(32);
    	assembly { mstore(add(b, 32), x) }
	}
	
	function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}

contract GAMMA { // Γ - mv - NFT - mkt - γ
    using SafeMath for uint256;
    uint256 public constant GAMMA_MAX = 5772156649015328606065120900824024310421;
    uint256 public totalSupply;
    uint256 public royalties = 10;
    string public name = "GAMMA";
    string public symbol = "GAMMA";
    string public gRoyaltiesURI;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public tokenByIndex;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => Sale) public sale;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;
    mapping(uint256 => address payable) public gRoyaltiesByTokenId;
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateSale(uint256 indexed ethPrice, uint256 indexed tokenId, uint8 forSale);
    struct Sale {
        uint256 ethPrice;
        uint8 forSale;
    }
    constructor (string memory _gRoyaltiesURI) public {
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
        gRoyaltiesURI = _gRoyaltiesURI;
    }
    function approve(address spender, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    function mint(uint256 ethPrice, string calldata _tokenURI, uint8 forSale, address creator) external { 
        totalSupply++;
        require(totalSupply <= GAMMA_MAX, "maxed");
        uint256 tokenId = totalSupply;
        balanceOf[msg.sender]++;
        ownerOf[tokenId] = msg.sender;
        tokenByIndex[tokenId - 1] = tokenId;
        tokenURI[tokenId] = _tokenURI;
        sale[tokenId].ethPrice = ethPrice;
        sale[tokenId].forSale = forSale;
        tokenOfOwnerByIndex[msg.sender][tokenId - 1] = tokenId;
        
        // mint royalties token and transfer to artist
        gRoyalties g = new gRoyalties();
        g.mint(Utilities.append(name, " Royalties Token"), gRoyaltiesURI);
        g.transfer(creator, 1);
        gRoyaltiesByTokenId[tokenId] = address(g);
        
        emit Transfer(address(0), msg.sender, tokenId); 
        emit UpdateSale(ethPrice, tokenId, forSale);
    }
    function purchase(uint256 tokenId) payable external {
        require(msg.value == sale[tokenId].ethPrice, "!ethPrice");
        require(sale[tokenId].forSale == 1, "!forSale");

        uint256 r = sale[tokenId].ethPrice.mul(royalties).div(100);
        (bool success, ) = gRoyaltiesByTokenId[tokenId].call{value: r}("");
        require(success, "!transfer");
        
        uint256 payout = sale[tokenId].ethPrice.sub(r);
        (success, ) = ownerOf[tokenId].call{value: payout}("");
        require(success, "!transfer");
        _transfer(ownerOf[tokenId], msg.sender, tokenId);
    }
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function _transfer(address from, address to, uint256 tokenId) internal {
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = to;
        sale[tokenId].forSale = 0;
        tokenOfOwnerByIndex[from][tokenId - 1] = 0;
        tokenOfOwnerByIndex[to][tokenId - 1] = tokenId;
        emit Transfer(from, to, tokenId); 
    }
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        _transfer(msg.sender, to, tokenId);
    }
    function transferBatch(address[] calldata to, uint256[] calldata tokenId) external {
        require(to.length == tokenId.length, "!to/tokenId");
        for (uint256 i = 0; i < to.length; i++) {
            require(msg.sender == ownerOf[tokenId[i]], "!owner");
            _transfer(msg.sender, to[i], tokenId[i]);
        }
    }
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || getApproved[tokenId] == msg.sender || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/spender/operator");
        _transfer(from, to, tokenId);
    }
    
    function updateSale(uint256 ethPrice, uint256 tokenId, uint8 forSale) payable external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        sale[tokenId].ethPrice = ethPrice;
        sale[tokenId].forSale = forSale;
        emit UpdateSale(ethPrice, tokenId, forSale);
    }
    function updateRoyalties(uint256 _royalties) external {
        royalties = _royalties;
    }
}

contract gRoyalties { // Γ - mv - NFT - mkt - γ
    uint256 public totalSupply = 1;
    string public name;
    string public symbol= "gRoyalties";
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public tokenByIndex;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => Sale) public sale;
    mapping(bytes4 => bool) public supportsInterface; // eip-165 
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(address => mapping(uint256 => uint256)) public tokenOfOwnerByIndex;
    event Approval(address indexed approver, address indexed spender, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateSale(uint256 indexed ethPrice, uint256 indexed tokenId, bool forSale);
    struct Sale {
        uint256 ethPrice;
        bool forSale;
    }
    constructor () public {
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
    }
    function approve(address spender, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    function mint(string calldata _name, string calldata _tokenURI) external { 
        name = _name;
        // use totalSupply as tokenId
        balanceOf[msg.sender]++;
        ownerOf[totalSupply] = msg.sender;
        tokenByIndex[totalSupply - 1] = totalSupply;
        tokenURI[totalSupply] = _tokenURI;
        tokenOfOwnerByIndex[msg.sender][totalSupply - 1] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply); 
    }
    function purchase(uint256 tokenId) payable external {
        require(msg.value == sale[tokenId].ethPrice, "!ethPrice");
        require(sale[tokenId].forSale, "!forSale");
        (bool success, ) = ownerOf[tokenId].call{value: msg.value}("");
        require(success, "!transfer");
        _transfer(ownerOf[tokenId], msg.sender, tokenId);
    }
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function _transfer(address from, address to, uint256 tokenId) internal {
        balanceOf[from]--; 
        balanceOf[to]++; 
        getApproved[tokenId] = address(0);
        ownerOf[tokenId] = to;
        sale[tokenId].forSale = false;
        tokenOfOwnerByIndex[from][tokenId - 1] = 0;
        tokenOfOwnerByIndex[to][tokenId - 1] = tokenId;
        emit Transfer(from, to, tokenId); 
    }
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        _transfer(msg.sender, to, tokenId);
    }
    function transferFrom(address from, address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || getApproved[tokenId] == msg.sender || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/spender/operator");
        _transfer(from, to, tokenId);
    }
    function updateSale(uint256 ethPrice, uint256 tokenId, bool forSale) payable external {
        require(msg.sender == ownerOf[tokenId], "!owner");
        sale[tokenId].ethPrice = ethPrice;
        sale[tokenId].forSale = forSale;
        emit UpdateSale(ethPrice, tokenId, forSale);
    }
    function withdraw() payable public {
        require(msg.sender == ownerOf[totalSupply], "!owner");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "!transfer");        
    }
    
    receive() external payable {  require(msg.data.length ==0); }
}

contract LiteToken { // minimal viable erc20 token with common extensions, such as burn, cap, mint, pauseable, admin functions
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
    bool public transferable; 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner, uint256 _initialSupply, uint256 _totalSupplyCap, bool _transferable) public {require(_initialSupply <= _totalSupplyCap, "capped");
        name = _name; symbol = _symbol; decimals = _decimals; owner = _owner; totalSupply = _initialSupply; totalSupplyCap = _totalSupplyCap; transferable = _transferable; balanceOf[owner] = totalSupply; emit Transfer(address(0), owner, totalSupply);}
    function approve(address spender, uint256 amount) external returns (bool) {require(amount == 0 || allowance[msg.sender][spender] == 0); allowance[msg.sender][spender] = amount; emit Approval(msg.sender, spender, amount); return true;}
    function burn(uint256 amount) external {balanceOf[msg.sender] = balanceOf[msg.sender] - amount; totalSupply = totalSupply - amount; emit Transfer(msg.sender, address(0), amount);}
    function mint(address recipient, uint256 amount) external {require(msg.sender == owner, "!owner"); require(totalSupply + amount <= totalSupplyCap, "capped"); balanceOf[recipient] = balanceOf[recipient] + amount; totalSupply = totalSupply + amount; emit Transfer(address(0), recipient, amount);}
    function transfer(address recipient, uint256 amount) external returns (bool) {require(transferable == true); balanceOf[msg.sender] = balanceOf[msg.sender] - amount; balanceOf[recipient] = balanceOf[recipient] + amount; emit Transfer(msg.sender, recipient, amount); return true;}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {require(transferable == true); balanceOf[sender] = balanceOf[sender] - amount; balanceOf[recipient] = balanceOf[recipient] + amount; allowance[sender][msg.sender] = allowance[sender][msg.sender] - amount; emit Transfer(sender, recipient, amount); return true;}
    function transferOwner(address _owner) external {require(msg.sender == owner, "!owner"); owner = _owner;}
    function updateTransferability(bool _transferable) external {require(msg.sender == owner, "!owner"); transferable = _transferable;}
}

contract MolVault {
    using SafeMath for uint256;
    address vault = address(this);
    address payable[] public owners;
    address payable[] public whitelist;
    address payable[] public bidOwners;
    address payable[] public proposedOwners;
    address payable public bidder;
    uint8 public numConfirmationsRequired;
    uint8 public numWithdrawalConfirmations;
    uint8 public numSaleConfirmations;
    uint8 public numProposedOwnersConfirmations;
    uint256 public bid;
    uint256 public gammaSupply;
    uint256 public fundingGoal;
    uint256 public fundingGoalPerc = 100;
    // bytes[] public depositTokens;
    
    GAMMA public gamma;
    
    // Vault Shares
    LiteToken vaultShares;
    uint256 public airdrop = 100000000000000000000;
    uint256 public circulatedShares;
    uint8 public isFunded;
    address payable[] public fundingCollectors;
    
    // Fees
    uint8 public percFeeToFundingCollectors = 5;
    uint8 public percFeeToWhitelist = 5;
    
    struct Sale {
        address sender;
        uint8 forSale; // 1 = sale active, 0 = sale inactive
        uint256 ethPrice;
        uint256 tokenPrice;
    }
    
    mapping (bytes => bool) public NFTs;
	mapping (bytes => Sale) public sale;
    mapping (address => bool) public isOwner;
    mapping (address => bool) public isWhitelisted;
    mapping (address => bool) public withdrawalConfirmed;
    mapping (address => bool) public saleConfirmed;
    mapping (address => bool) public proposedOwnersConfirmed;
    mapping (address => uint) public fundingCollectorPerc;

    constructor(
        address payable[] memory _owners, 
        uint8 _numConfirmationsRequired, 
        string memory _name, 
        string memory _symbol, 
        uint256 _fundingGoal, 
        string memory _gRoyaltiesURI
        ) public {
        require(_owners.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address payable owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
            
            isWhitelisted[owner] = true;
            whitelist.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        fundingGoal = _fundingGoal;
        vaultShares = new LiteToken(_name, _symbol, 18, vault, 0, 1000000000000000000000000, false);
        gamma = new GAMMA(_gRoyaltiesURI);
    }
    
    modifier onlyOwners() {
        require(isOwner[msg.sender], "!owner");
        _;
    }
    
    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "!whitelisted");
        _;
    }
    
    function mint(uint256 _ethPrice, uint256 _tokenPrice, string memory _tokenURI, uint8 _forSale) public onlyWhitelisted{
        gammaSupply++;
        gamma.mint(_ethPrice, _tokenURI, _forSale, msg.sender);
        bytes memory tokenKey = getTokenKey(address(gamma), gammaSupply);
        NFTs[tokenKey] = true;
        sale[tokenKey].sender = msg.sender;
        sale[tokenKey].ethPrice = _ethPrice;
        sale[tokenKey].tokenPrice = _tokenPrice;
        sale[tokenKey].forSale = _forSale;
        vaultShares.mint(msg.sender, airdrop.mul(2)); 
        circulatedShares += airdrop.mul(2);
    }
    
//     function deposit(
//         address _tokenAddress, 
//         uint256 _tokenId, 
//         uint256 _ethPrice,
//         uint256 _tokenPrice, 
//         uint8 _forSale) 
//         public onlyWhitelisted {
// 		require(IERC721(_tokenAddress).ownerOf(_tokenId) == msg.sender, "!owner");
//         bytes memory tokenKey = getTokenKey(_tokenAddress, _tokenId);
        
//         // Deposit NFT
//         depositTokens.push(tokenKey);
//         NFTs[tokenKey] = true;
//         IERC721(_tokenAddress).transferFrom(msg.sender, vault, _tokenId);
    
//         // Set sale status
//         sale[tokenKey].sender = msg.sender;
//         sale[tokenKey].ethPrice = _ethPrice;
//         sale[tokenKey].tokenPrice = _tokenPrice;
//         sale[tokenKey].forSale = _forSale;  
// 	}
    
    function distributeFeeToFundingCollectors(uint256 fee) private {
        for (uint i = 0; i < fundingCollectors.length; i++) {
            uint split = (fundingCollectorPerc[fundingCollectors[i]].mul(fee)).div(100);
            (bool success, ) = fundingCollectors[i].call{value: split}("");
            require(success, "!transfer");
        }
    }
    
    function distributeFeeToWhitelist(uint256 fee) private {
        for (uint i = 0; i < whitelist.length; i++) {
            uint split = fee.div(whitelist.length);
            (bool success, ) = whitelist[i].call{value: split}("");
            require(success, "!transfer");
        }
    }
    
    function purchase(address _tokenAddress, uint256 _tokenId) public payable {
        bytes memory tokenKey = getTokenKey(_tokenAddress, _tokenId);
        require(sale[tokenKey].forSale == 1, "!sale");
        require(sale[tokenKey].sender != msg.sender, 'Sender cannot buy!');
        require(!isOwner[msg.sender], "Owners cannot buy!");
        
        uint256 feeToFundingCollectors = sale[tokenKey].ethPrice.mul(percFeeToFundingCollectors).div(1000);
        uint256 feeToWhitelist = sale[tokenKey].ethPrice.mul(percFeeToWhitelist).div(1000);
        require((sale[tokenKey].ethPrice + feeToFundingCollectors + feeToWhitelist) == msg.value, "!price");
        
        if (fundingGoalPerc > 0) {
            // check if fundingCollector 
            if (fundingCollectorPerc[msg.sender] == 0) {
               fundingCollectors.push(msg.sender); 
               uint perc = msg.value.mul(100).div(fundingGoal); 
            
               if (perc > fundingGoalPerc) {
                   fundingCollectorPerc[msg.sender] = fundingGoalPerc;
                   fundingGoalPerc = 0;
               } else {
                   fundingCollectorPerc[msg.sender] = perc;
                   fundingGoalPerc = fundingGoalPerc - perc;
               }
            }
            (bool success, ) = vault.call{value: sale[tokenKey].ethPrice}("");
            require(success, "!transfer");
        } else {
            isFunded = 1;

            (bool success, ) = vault.call{value: sale[tokenKey].ethPrice}("");
            require(success, "!transfer");
            
            distributeFeeToFundingCollectors(feeToFundingCollectors);
            distributeFeeToWhitelist(feeToWhitelist);
            vaultShares.mint(msg.sender, airdrop);
            circulatedShares += airdrop;
        }
        
        IERC721(_tokenAddress).transferFrom(vault, msg.sender, _tokenId);
        sale[tokenKey].forSale = 0;
        NFTs[tokenKey] = false;
    }
    
    function tokenPurchase(address _tokenAddress, uint256 _tokenId) public payable {
        bytes memory tokenKey = getTokenKey(_tokenAddress, _tokenId);
        require(sale[tokenKey].forSale == 1, "!sale");
        require(vaultShares.balanceOf(msg.sender) >= sale[tokenKey].tokenPrice, "!price");
        require(!isOwner[msg.sender], "Owners cannot buy!");

        vaultShares.updateTransferability(true);
        vaultShares.transferFrom(msg.sender, vault, sale[tokenKey].tokenPrice); 
        vaultShares.updateTransferability(false);
        
        IERC721(_tokenAddress).transferFrom(vault, msg.sender, _tokenId);
        sale[tokenKey].forSale == 0;
        NFTs[tokenKey] = false;
    }
    
    function updateSale(address _tokenAddress, uint256 _tokenId, uint256 _ethPrice, uint256 _tokenPrice, uint8 _forSale) public {
        bytes memory tokenKey = getTokenKey(_tokenAddress, _tokenId);
        require(sale[tokenKey].sender == msg.sender, "!sender");
        sale[tokenKey].ethPrice = _ethPrice;
        sale[tokenKey].tokenPrice = _tokenPrice;
        sale[tokenKey].forSale = _forSale;  
    }
    
    function confirmSale() public onlyOwners {
        require(!saleConfirmed[msg.sender], 'Msg.sender already confirmed vault sale!');
	    numSaleConfirmations++;
	    saleConfirmed[msg.sender] = true;
	}
	
	function revokeSale() public onlyOwners {
        require(saleConfirmed[msg.sender], 'Msg.sender did not confirm vault sale!');
	    numSaleConfirmations--;
	    saleConfirmed[msg.sender] = false;
	}
    
    function bidVault(address payable[] memory _newOwners) public payable {
        require(msg.value > bid, 'You must bid higher than the existing bid!'); 
        require(_newOwners.length > 0, "There must be at least one new owner!");
        
        (bool success, ) = bidder.call{value: bid}("");
        require(success, "!transfer");
        
        bidder = msg.sender;
        bid = msg.value;
        bidOwners = _newOwners;
    }
    
    function withdrawBid() public {
        require(bidder == msg.sender, '!bidder');
        
        (bool success, ) = bidder.call{value: bid}("");
        require(success, "!transfer");
        
        bidder = msg.sender;
        bid = 0;
        bidOwners = [address(0)];
    }
    
    function sellVault() public onlyOwners {
	    require(numSaleConfirmations >= numConfirmationsRequired, "!numConfirmationsRequired");
        uint256 cut = (bid / owners.length);

        // Reset sale confirmations
        for (uint8 i = 0; i < owners.length; i++) {
	        (bool success, ) = owners[i].call{value: cut}("");
            require(success, "!transfer");
            saleConfirmed[owners[i]] = false;
            numSaleConfirmations = 0;
	    }
        
        // Clear ownership
        for (uint8 i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = false;
        }
        
        // Transition ownership 
        owners = bidOwners;
        
        for (uint8 i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = true;
        }
        
        // Clear whitelist
        for (uint8 i = 0; i < whitelist.length; i++) {
            isWhitelisted[whitelist[i]] = false;
        }
        
        // Reset bid and bidder
        bidder = address(0);
        bid = 0;
    }
	
	function confirmWithdrawal() public onlyOwners {
	    require(!withdrawalConfirmed[msg.sender], 'Withdrawal already confirmed!');
	    numWithdrawalConfirmations++;
	    withdrawalConfirmed[msg.sender] = true;
	}
	
	function revokeWithdrawal() public onlyOwners { 
	    require(withdrawalConfirmed[msg.sender], 'Withdrawal not confirmed!');
	    numWithdrawalConfirmations--;
	    withdrawalConfirmed[msg.sender] = false;
	}
	
	function executeWithdrawal(uint256 _amount, address payable _address) public onlyOwners {
	    require(isFunded == 1, "Vault shares not minted!");
	    require(numWithdrawalConfirmations >= numConfirmationsRequired, "!numConfirmationsRequired");
	    require(address(this).balance >= _amount, 'Insufficient funds.');
	    
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "!transfer");

	    for (uint8 i = 0; i < owners.length; i++){
            withdrawalConfirmed[owners[i]] = false;
	    }
	    
	    numWithdrawalConfirmations = 0;
	}
	
	function addToWhitelist(address payable[] memory _address) public onlyOwners {
	    for (uint8 i = 0; i < _address.length; i++) {
	        address payable newAddress = _address[i];
	        require(!isWhitelisted[newAddress], "Already whitelisted!");
	        isWhitelisted[newAddress] = true;
	        whitelist.push(newAddress);
	    }
	}
	
	function removeFromWhitelist(address[] memory _address) public onlyOwners {
	    for (uint8 i = 0; i < _address.length; i++) {
	        address newAddress = _address[i];
	        require(isWhitelisted[newAddress], "No address to remove!");
	        isWhitelisted[newAddress] = false;
	        
	        for (uint8 j = 0; j < whitelist.length; j++) {
	            if (newAddress == whitelist[j]) {
	                whitelist[j] = address(0);
	            }
	        }
	    }
	}
	
	function getWhitelist() public view returns (address[] memory) {
	    address[] memory roster = new address[](whitelist.length);
	    for (uint i = 0; i < whitelist.length; i++) {
	        roster[i] = whitelist[i];
	    }    
	    return roster;
	}
	
	function getFundingCollectors() public view returns (address[] memory) {
	    address[] memory funders = new address[](fundingCollectors.length);
	    for (uint i = 0; i < fundingCollectors.length; i++) {
	        funders[i] = fundingCollectors[i];
	    }
	    return funders;
	}
	
	function getBidOwners() public view returns (address[] memory) {
	    address[] memory nOwners = new address[](bidOwners.length);
	    for (uint i = 0; i < bidOwners.length; i++) {
	        nOwners[i] = bidOwners[i];
	    }
	    return nOwners;
	}
	
	function getProposedOwners() public view returns (address[] memory) {
	    address[] memory nOwners = new address[](proposedOwners.length);
	    for (uint i = 0; i < proposedOwners.length; i++) {
	        nOwners[i] = proposedOwners[i];
	    }
	    return nOwners;
	}
	
// 	function getDepositTokens() public view returns (bytes[] memory) {
// 	    bytes[] memory tokens = new bytes[](depositTokens.length);
// 	    for (uint i = 0; i < depositTokens.length; i++) {
// 	        tokens[i] = depositTokens[i];
// 	    }    
// 	    return tokens;
// 	}
	
	function removeGamma(address _tokenAddress, uint256 _tokenId) public onlyOwners {
        IERC721(_tokenAddress).transferFrom(vault, msg.sender, _tokenId);
	}
	
	function updateAirdrop(uint256 amount) public onlyOwners {
	    airdrop = amount;
	}
	
	function updateFeeDistribution(uint8 _percFeeToFundingCollectors, uint8 _percFeeToWhitelist) public onlyOwners {
	    percFeeToFundingCollectors = _percFeeToFundingCollectors;
	    percFeeToWhitelist = _percFeeToWhitelist;
	}
	
	// Update community organizers
	function proposeOwners(address payable[] memory _newOwners) public onlyOwners {
	    require(_newOwners.length > 0, '!_newOwners');
	    proposedOwners = _newOwners;
	}
	
	function confirmOwnersUpdate() public onlyOwners {
	    require(!proposedOwnersConfirmed[msg.sender], 'Already confirmed proposed owners!');
	    require(proposedOwners.length > 0, '!newProposedOwners');
	    numProposedOwnersConfirmations++;
	    proposedOwnersConfirmed[msg.sender] = true;
	}
	
	function revokeOwnersUpdate() public onlyOwners { 
	    require(proposedOwnersConfirmed[msg.sender], 'Proposed owners not yet confirmed!');
	    numProposedOwnersConfirmations--;
	    proposedOwnersConfirmed[msg.sender] = false;
	}
	
	function updateOwners() public onlyOwners {
	    require(numProposedOwnersConfirmations >= numConfirmationsRequired, "!numConfirmationsRequired");
	    
	    // Clear ownership
        for (uint8 i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = false;
        }
        
        // Transition ownership 
        owners = proposedOwners;

        for (uint8 i = 0; i < owners.length; i++) {
            isOwner[owners[i]] = true;
        }
        
        for (uint8 i = 0; i < proposedOwners.length; i++) {
            proposedOwners[i] = address(0);
        }
	}
	
    function updateRoyalties(uint256 _royalties) public onlyOwners {
        gamma.updateRoyalties(_royalties);
    }
	
	function redeemFunds() public onlyWhitelisted {
	    require(vaultShares.balanceOf(msg.sender) > 0, 'No vaultShares to redeem!');
	    require(isFunded == 1, 'Vault not funded!');
	    uint256 availableFunds = address(this).balance.sub(fundingGoal);
	    uint256 prorata = (vaultShares.balanceOf(msg.sender)).mul(100).div(circulatedShares);
	    (bool success, ) = msg.sender.call{value: availableFunds.mul(prorata).div(100)}("");
	    require(success, "!transfer");
	    
	    vaultShares.updateTransferability(true);
        vaultShares.transferFrom(msg.sender, vault, vaultShares.balanceOf(msg.sender)); 
        vaultShares.updateTransferability(false);
        
        circulatedShares -= vaultShares.balanceOf(msg.sender);
	}
	
    // Function for getting the document key for a given NFT address + tokenId
	function getTokenKey(address tokenAddress, uint256 tokenId) public pure returns (bytes memory) {
		return Utilities.concat(Utilities.toBytes(tokenAddress), Utilities.toBytes(tokenId));
	}
	
    receive() external payable {  require(msg.data.length ==0); }
}