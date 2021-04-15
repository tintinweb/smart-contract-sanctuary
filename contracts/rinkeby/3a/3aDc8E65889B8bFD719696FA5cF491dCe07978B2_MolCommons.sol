/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
/// SPDX-License-Identifier: GPL-3.0-or-later

// import './MolAuction.sol';

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Utilities {
	function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}

contract GAMMA { // Γ - mv - NFT - mkt - γ
    using SafeMath for uint256;
    LiteToken public coin;
    MolCommons public commons;
    uint256 public constant GAMMA_MAX = 5772156649015328606065120900824024310421;
    uint256 public totalSupply;
    uint256 public royalties = 10;
    string public name;
    string public symbol;
    string public gRoyaltiesURI;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public tokenByIndex;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => Sale) public sales;
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
        uint256 coinPrice;
        uint8 forSale;
        address minter;
    }
    constructor (string memory _name, string memory _symbol, string memory _gRoyaltiesURI, address _coin, address payable _commons) public {
        supportsInterface[0x80ac58cd] = true; // ERC721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x780e9d63] = true; // ENUMERABLE
        name = _name;
        symbol = _symbol;
        gRoyaltiesURI = _gRoyaltiesURI;
        coin = LiteToken(_coin);
        commons = MolCommons(_commons);
    }
    function approve(address spender, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId] || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/operator");
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId); 
    }
    function mint(uint256 ethPrice, uint256 coinPrice, string calldata _tokenURI, uint8 forSale, address minter) external { 
        totalSupply++;
        require(totalSupply <= GAMMA_MAX, "maxed");
        require(commons.isCreator(minter), "!creator");
        uint256 tokenId = totalSupply;
        balanceOf[msg.sender]++;
        ownerOf[tokenId] = msg.sender;
        tokenByIndex[tokenId - 1] = tokenId;
        tokenURI[tokenId] = _tokenURI;
        sales[tokenId].ethPrice = ethPrice;
        sales[tokenId].coinPrice = coinPrice;
        sales[tokenId].forSale = forSale;
        sales[tokenId].minter = minter;
        tokenOfOwnerByIndex[msg.sender][tokenId - 1] = tokenId;
        
        // mint royalties token and transfer to artist
        gRoyalties g = new gRoyalties();
        g.mint(Utilities.append(name, " Royalties Token"), gRoyaltiesURI);
        g.transfer(minter, 1);
        gRoyaltiesByTokenId[tokenId] = address(g);
        
        emit Transfer(address(0), msg.sender, tokenId); 
        emit UpdateSale(ethPrice, tokenId, forSale);
    }
    function purchase(uint256 tokenId) payable external {
        if (ownerOf[tokenId] == address(commons)) {
            revert("Must go through commons' purchase function!");
        }
        require(msg.value == sales[tokenId].ethPrice, "!ethPrice");
        require(sales[tokenId].forSale == 1, "!forSale");

        uint256 r = sales[tokenId].ethPrice.mul(royalties).div(100);
        (bool success, ) = gRoyaltiesByTokenId[tokenId].call{value: r}("");
        require(success, "!transfer");
        
        uint256 payout = sales[tokenId].ethPrice.sub(r);
        (success, ) = ownerOf[tokenId].call{value: payout}("");
        require(success, "!transfer");
        _transfer(ownerOf[tokenId], msg.sender, tokenId);
        
        sales[tokenId].forSale = 0;
    }
    function coinPurchase(uint256 tokenId) external {
        if (!coin.transferable()) {
            revert('Coin is non-transferable, please use purchase function in MolCommons!');
        }
        
        require(coin.balanceOf(msg.sender) >= sales[tokenId].coinPrice, "!price");
        require(sales[tokenId].forSale == 1, "!forSale");

        coin.transferFrom(msg.sender, sales[tokenId].minter, sales[tokenId].coinPrice); 
        
        _transfer(ownerOf[tokenId], msg.sender, tokenId);
        sales[tokenId].ethPrice = 0;
        sales[tokenId].coinPrice = 0;
        sales[tokenId].forSale = 0;
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
        sales[tokenId].forSale = 0;
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
    
    function updateSale(uint256 ethPrice, uint256 coinPrice, uint256 tokenId, uint8 forSale) external {
        require(msg.sender == ownerOf[tokenId] || isApprovedForAll[ownerOf[tokenId]][msg.sender], "!owner/operator");
        sales[tokenId].ethPrice = ethPrice;
        sales[tokenId].coinPrice = coinPrice;
        sales[tokenId].forSale = forSale;
        emit UpdateSale(ethPrice, tokenId, forSale);
    }
    function getSale(uint256 tokenId) public view returns (uint, uint, uint, address) {
        return (sales[tokenId].ethPrice, sales[tokenId].coinPrice, sales[tokenId].forSale, sales[tokenId].minter);
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

contract MolCommons {
    using SafeMath for uint256;
    
    // Commons
    address payable commons = address(this);
    address payable[] public organizers;
    mapping (address => bool) public isOrganizer;
    uint8[3] public confirmations; // [numConfirmationsRequired, numBidConfirmations, numWithdrawalConfirmations]
    
    // Creators
    address payable[] public creators;
    mapping (address => bool) public isCreator;
    
    // Bid
    uint256 public bid;
    address payable public bidder;
    address payable[] public newOrganizers;
    mapping (address => bool) public bidConfirmed;
   
    // Withdraw funds
    mapping (address => bool) public withdrawalConfirmed;

    // NFT
    GAMMA public gamma;

    // Commons coins
    LiteToken public coin;
    uint256 public airdrop = 100000000000000000000;
    
    // Fees
    uint8[2] public fees = [1, 1]; // [percFeeToCreators, percFeeToContributors]
    address payable[] contributors;

    // Approved contracts
    mapping (address => bool) public isApprovedContract;
    constructor(
        address payable[] memory _organizers, 
        uint8 _numConfirmationsRequired, 
        string memory _nftName, 
        string memory _nftSymbol, 
        string memory _coinName, 
        string memory _coinSymbol, 
        string memory _gRoyaltiesURI,
        bool _transferable
        ) public {
        require(_organizers.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _organizers.length, "invalid number of required confirmations");

        for (uint i = 0; i < _organizers.length; i++) {
            address payable org = _organizers[i];

            require(org != address(0), "Invalid organizer!");
            require(!isOrganizer[org], "Organizer not unique!");

            isOrganizer[org] = true;
            organizers.push(org);
            
            isCreator[org] = true;
            creators.push(org);
        }

        confirmations[0] = _numConfirmationsRequired;
        coin = new LiteToken(_coinName, _coinSymbol, 18, commons, 0, 1000000000000000000000000, _transferable);
        gamma = new GAMMA(_nftName, _nftSymbol, _gRoyaltiesURI, address(coin), commons);
    }
    
    modifier onlyOrganizers() {
        require(isOrganizer[msg.sender], "!organizer");
        _;
    }
    
    modifier onlyCreators() {
        require(isCreator[msg.sender], "!creator");
        _;
    }
    
    modifier onlyApprovedContracts() {
        require(isApprovedContract[msg.sender], "Contract not approved!");
        _;
    }
    
    // ******* // 
	//  GAMMA  //
	// ******* //
	
    function mint(uint256 _ethPrice, uint256 _coinPrice, string memory _tokenURI, uint8 _forSale, uint256 _airdropAmount) public onlyCreators{
        gamma.mint(_ethPrice, _coinPrice, _tokenURI, _forSale, msg.sender);

        // Airdrop coin
        coin.mint(msg.sender, _airdropAmount); 
    }
    
    function updateSale(uint256 _ethPrice, uint256 _coinPrice, uint256 _tokenId, uint8 _forSale) public {
        gamma.updateSale(_ethPrice, _coinPrice, _tokenId, _forSale);    
    }
    
    // ********* // 
	// BUY GAMMA //
	// ********* //
	
    function distributeFeeToContributors(uint256 fee) private {
        if (contributors.length == 0) {
            // (bool success, ) = commons.call{value: fee}("");
            // require(success, "!transfer");
            distributeFeeToCreators(fee);
        } else {
            uint split = fee.div(contributors.length);
            for (uint i = 0; i < contributors.length; i++) {
                (bool success, ) = contributors[i].call{value: split}("");
                require(success, "!transfer");
            }
        }
    }
    
    function distributeFeeToCreators(uint256 fee) private {
        uint split = fee.div(creators.length);
        for (uint i = 0; i < creators.length; i++) {
            if (!isCreator[creators[i]]) {
                continue;
            }
            (bool success, ) = creators[i].call{value: split}("");
            require(success, "!transfer");
        }
    }
    
    function purchase(uint256 _tokenId, uint256 _airdropAmount) public payable {
        (uint ethPrice, , uint forSale,) = gamma.getSale(_tokenId);
        require(forSale == 1, '!sale');
        
        uint256 feeToCreators = ethPrice.mul(fees[0]).div(100);
        uint256 feeToContributors = ethPrice.mul(fees[1]).div(100);
        require(ethPrice.add(feeToCreators).add(feeToContributors) == msg.value, "!price");

        (bool success, ) = commons.call{value: ethPrice}("");
        require(success, "!transfer");
        
        distributeFeeToCreators(feeToCreators);
        distributeFeeToContributors(feeToContributors);

        gamma.updateSale(0, 0, _tokenId, 0);
        gamma.transfer(msg.sender, _tokenId);

        // Airdrop coin
        coin.mint(msg.sender, _airdropAmount);
    }
    
    function coinPurchase(uint256 _tokenId) public payable {
        if (coin.transferable()) {
            revert('Coin is transferable, please use purchase function in GAMMA');
        }
        
        (, uint coinPrice, uint forSale,) = gamma.getSale(_tokenId);
        require(forSale == 1, '!sale');
        require(coin.balanceOf(msg.sender) >= coinPrice, "!price");

        coin.updateTransferability(true);
        coin.transferFrom(msg.sender, gamma.ownerOf(_tokenId), coinPrice); 
        coin.updateTransferability(false);
        
        gamma.updateSale(0, 0, _tokenId, 0);
        gamma.transfer(msg.sender, _tokenId);
    }
    
    // *********** // 
	// BID COMMONS //
	// *********** //
	
    // ----- Bid (public functions)
    function bidCommons(address payable[] memory _newOwners) public payable {
        require(msg.value > bid, 'You must bid higher than the existing bid!'); 
        require(_newOwners.length > 0, "There must be at least one new owner!");
        
        (bool success, ) = bidder.call{value: bid}("");
        require(success, "!transfer");
        
        bidder = msg.sender;
        bid = msg.value;
        newOrganizers = _newOwners;
    }
    
    function withdrawBid() public {
        require(bidder == msg.sender, '!bidder');
        
        (bool success, ) = bidder.call{value: bid}("");
        require(success, "!transfer");
        
        bidder = msg.sender;
        bid = 0;
        newOrganizers = [address(0)];
    }
    
	function getBidOwners() public view returns (address[] memory) {
	    address[] memory nOrganizers = new address[](newOrganizers.length);
	    for (uint i = 0; i < newOrganizers.length; i++) {
	        nOrganizers[i] = newOrganizers[i];
	    }
	    return nOrganizers;
	}
	
    // ----- Bid (admin functions)
    function confirmBid() public onlyOrganizers {
        require(!bidConfirmed[msg.sender], 'Msg.sender already confirmed vault sale!');
	    confirmations[1]++;
	    bidConfirmed[msg.sender] = true;
	}
	
	function revokeBidConfirmation() public onlyOrganizers {
        require(bidConfirmed[msg.sender], 'Msg.sender did not confirm vault sale!');
	    confirmations[1]--;
	    bidConfirmed[msg.sender] = false;
	}
    
    function executeBid() public onlyOrganizers {
	    require(confirmations[1] >= confirmations[0], "!numConfirmationsRequired");
        uint256 cut = (bid.div(organizers.length));

        // Reset sale confirmations
        for (uint8 i = 0; i < organizers.length; i++) {
	        (bool success, ) = organizers[i].call{value: cut}("");
            require(success, "!transfer");
            bidConfirmed[organizers[i]] = false;
            confirmations[1] = 0;
	    }
        
        // Clear ownership
        for (uint8 i = 0; i < organizers.length; i++) {
            isOrganizer[organizers[i]] = false;
        }
        
        // Transition ownership 
        organizers = newOrganizers;
        
        for (uint8 i = 0; i < organizers.length; i++) {
            isOrganizer[organizers[i]] = true;
        }
        
        // Clear whitelist (??)
        for (uint8 i = 0; i < creators.length; i++) {
            isCreator[creators[i]] = false;
        }
        
        // Reset bid and bidder
        bidder = address(0);
        bid = 0;
    }
	
	// ************** // 
	// WITHDRAW FUNDS //
	// ************** //
	
	function confirmWithdrawal() public onlyOrganizers {
	    require(!withdrawalConfirmed[msg.sender], 'Withdrawal already confirmed!');
	    confirmations[2]++;
	    withdrawalConfirmed[msg.sender] = true;
	}
	
	function revokeWithdrawal() public onlyOrganizers { 
	    require(withdrawalConfirmed[msg.sender], 'Withdrawal not confirmed!');
	    confirmations[2]--;
	    withdrawalConfirmed[msg.sender] = false;
	}
	
	function executeWithdrawal(uint256 _amount, address payable _address) public onlyOrganizers {
	    require(confirmations[2] >= confirmations[0], "!numConfirmationsRequired");
	    require(address(this).balance >= _amount, 'Insufficient funds.');
	    
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "!transfer");

	    for (uint8 i = 0; i < organizers.length; i++){
            withdrawalConfirmed[organizers[i]] = false;
	    }
	    
	    confirmations[2] = 0;
	}
	
	// ***************** // 
	// ROSTER MANAGEMENT //
	// ***************** // 
	
	function addCreator(address payable _address) public onlyOrganizers {
        require(!isCreator[_address], "Already whitelisted!");
        isCreator[_address] = true;
        creators.push(_address);
	}
	
	function removeCreator(address _address) public onlyOrganizers {
        require(isCreator[_address], "No address to remove!");
        isCreator[_address] = false;
	}
	
	function getCreators() public view returns (address[] memory) {
	    address[] memory roster = new address[](creators.length);
	    for (uint i = 0; i < creators.length; i++) {
	        roster[i] = creators[i];
	    }    
	    return roster;
	}
	
	// *************** // 
	// MISC MANAGEMENT //
	// *************** // 
	
	// ----- Remove Gamma from Commons
	function removeGamma(uint256 _tokenId, address recipient) public onlyOrganizers {
        gamma.transfer(recipient, _tokenId);
	}
	
	// ---- Update aridrop of coins
	function updateAirdrop(uint256 amount) public onlyOrganizers {
	    airdrop = amount;
	}
	
	// ----- Update distribution of tx fee
	function updateFeeDistribution(uint8 _percFeeToCreators, uint8 _percFeeToContributors) public onlyOrganizers {
	    fees[0] = _percFeeToCreators;
	    fees[1] = _percFeeToContributors;
	}
	
	// ----- Update contributors
	function updateContributors(address payable[] memory _contributors) public onlyOrganizers {
	    contributors = _contributors;
	}
	
	// ----- Update Gamma royalties 
    function updateRoyalties(uint256 _royalties) public onlyOrganizers {
        gamma.updateRoyalties(_royalties);
    }

    // ----- Approve contract to transfer gamma
	function approveContract(address _contract) public onlyCreators {
	    gamma.setApprovalForAll(_contract, true);
	    isApprovedContract[_contract] = true;
	}
	
	function dropCoin(address _recipient, uint256 _amount) public onlyApprovedContracts {
	    coin.mint(_recipient, _amount);
	}
	
    receive() external payable {  require(msg.data.length ==0); }
}