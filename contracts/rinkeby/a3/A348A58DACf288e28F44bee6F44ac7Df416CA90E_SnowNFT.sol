pragma solidity ^0.8.4;
//SPDX-License-Identifier: UNLICENSED
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract AccessControl {

    address public ceoAddress;
    address public cooAddress;

    bool public paused = false;

    function accessBossControl() public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _; 
    }
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    modifier onlyCLevel(){
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    modifier whenNotPaused {
        require(!paused);
        _;
    }
    modifier whenPaused {
        require(paused);
        _;
    }
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCOO(address _newCOO) public onlyCOO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    function pause() public onlyCEO whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
    
}

abstract contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    function totalSupply() public view virtual returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view virtual returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view virtual returns (address _owner);
    function approve(address _to, uint256 _tokenId) public virtual;
    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual;
    function implementsERC721() public virtual view returns (bool _implementsERC721);
    function takeOwnership(uint256 _tokenId) public virtual;
    function transfer(address _to, uint256 _tokenId) public virtual;
}

abstract contract DetailedERC721 is ERC721 {
    function name() public view  virtual returns (string memory _name);
    function symbol() public view virtual returns (string memory _symbol);
}


contract SnowNFT is AccessControl, DetailedERC721 {
    using SafeMath for uint256;
    event TokenCreated(uint256 tokenId, string name, uint256 price);
    event TokenSold(
        uint256 indexed tokenId,
        string name,
        uint256 sellingPrice,
        uint256 newPrice,
        address indexed oldOwner,
        address indexed newOwner
    );

    mapping (uint256 => address) private tokenIdToOwner;
    mapping (uint256 => uint256) private tokenIdToPrice;
    mapping (address => uint256) private ownershipTokenCount;
    mapping (uint256 => address) private tokenIdToApproved;

    struct Art {
        string name;
    }

    Art[] private artWorks;

    uint256 private startingPrice = 0.001 ether;
    bool private erc721Enabled = false;
    
    modifier onlyERC721() {
        require(erc721Enabled);
        _;
    }

    function createToken(string memory _name, address _owner, uint256 _price) public onlyCLevel {
        require(_owner != address(0));
        require(_price >= startingPrice);
        _createToken(_name, _owner, _price);
    }

    function createToken(string memory _name) public onlyCLevel {
        _createToken(_name, address(this), startingPrice);

    }

    function _createToken(string memory _name, address _owner, uint256 _price) private {
        Art memory _art = Art({
            name: _name
        });
         artWorks.push(_art);
         uint256 newTokenId = artWorks.length - 1;
        tokenIdToPrice[newTokenId] = _price;
        emit TokenCreated(newTokenId, _name, _price);
        _transfer(address(0),_owner, newTokenId);
    }

    function getToken(uint256 _tokenId) public view returns(
        string  memory _tokenName,
        uint256 _price,
        uint256 _nextPrice,
        address _owner
    ){
        _tokenName = artWorks[_tokenId].name;
        _price = tokenIdToPrice[_tokenId];
        _nextPrice = nextPriceOf(_tokenId);
        _owner = tokenIdToOwner[_tokenId];
    }

    function getAllTokens() public view returns( uint256[] memory, uint256[] memory, address[] memory){
        uint256 total = totalSupply();
        uint256[] memory prices = new uint256[](total);
        uint256[] memory nextPrice = new uint256[](total);
        address[] memory owners = new address[](total);

        for(uint256 i = 0; i < total; i++) {
            prices[i] = tokenIdToPrice[i];
            nextPrice[i] = nextPriceOf(i);
            owners[i] = tokenIdToOwner[i];
        }

        return (prices, nextPrice, owners);
    }

    function tokensOf(address _owner) public view returns(uint256[] memory){
        uint256 tokenCount = balanceOf(_owner);
        if(tokenCount == 0){
            return new uint256[](0);
        }else{
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;

            for(uint256 i = 0; i < total; i++){
                if(tokenIdToOwner[i] == _owner){
                    result[resultIndex] = i;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function withdrawBalance(address _to, uint256 _amount) public onlyCEO{
        require(_amount <= address(this).balance);
        uint256 amountToWithdraw = _amount;
        if(amountToWithdraw == 0){
            amountToWithdraw = address(this).balance;
        }
        if(_to == address(0)){
           payable (ceoAddress).transfer(amountToWithdraw);
        }else{
            payable( _to).transfer(amountToWithdraw);
        }
    }

    function purchase(uint256 _tokenId) public payable whenNotPaused {
        address oldOwner = ownerOf(_tokenId);
        address newOwner = msg.sender;
        uint256 sellingPrice = priceOf(_tokenId);

        require(oldOwner != address(0));
        require(newOwner != address(0));
        require(oldOwner != newOwner);
        require(!_isContract(newOwner));
        require(sellingPrice > 0);
        require(msg.value >= sellingPrice);

        _transfer(oldOwner, newOwner,_tokenId);
        tokenIdToPrice[_tokenId] = nextPriceOf(_tokenId);
        emit TokenSold(_tokenId, artWorks[_tokenId].name, sellingPrice, priceOf(_tokenId), oldOwner, newOwner);

        uint256 excess = msg.value.sub(sellingPrice);
        uint256 contractCut = sellingPrice.mul(10).div(100);
        if(oldOwner != address(this)){
           payable (oldOwner).transfer(sellingPrice.sub(contractCut));
        }
        if(excess > 0) {
           payable(newOwner).transfer(excess);
        }

    }

    function priceOf(uint256 _tokenId) public view returns (uint256 _price){
        return tokenIdToPrice[_tokenId];
    }

    uint256 private increaseLimit1 = 0.02 ether;
    uint256 private increaseLimit2 = 0.5 ether;
    uint256 private increaseLimit3 = 2.0 ether;
    uint256 private increaseLimit4 = 5.0 ether;

    function nextPriceOf(uint256 _tokenId) public view returns(uint256 _nextPrice){
        uint256 _price = priceOf(_tokenId);
        if(_price < increaseLimit1){
            return _price.mul(200).div(95);
        }else if(_price < increaseLimit2){
            return _price.mul(135).div(96);
        } else if(_price < increaseLimit3){
            return _price.mul(125).div(97);
        } else if(_price < increaseLimit4){
            return _price.mul(117).div(97);
        } else {
            return _price.mul(115).div(98);
        }
    }

    function enableERC721() public onlyCEO {
        erc721Enabled = true;
    }

    function totalSupply() public view override returns (uint256 _totalSupply){
        _totalSupply = artWorks.length;
    }
    function balanceOf(address _owner) public view override returns(uint256 _balance){
        _balance = ownershipTokenCount[_owner];
    }
    function ownerOf(uint256 _tokenId) public view override returns(address _owner){
        _owner = tokenIdToOwner[_tokenId];
    }
    function approve(address _to, uint256 _tokenId) public override whenNotPaused onlyCEO {
        require(_owns(msg.sender,_tokenId));
        tokenIdToApproved[_tokenId] = _to;
       emit Approval(msg.sender,_to,_tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public override whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(_from,_tokenId));
        require(_approved(msg.sender,_tokenId));
        _transfer(_from, _to, _tokenId);
    }
    function transfer(address _to, uint256 _tokenId) public override whenNotPaused onlyERC721 {
        require(_to != address(0));
        require(_owns(msg.sender,_tokenId));
        _transfer(msg.sender,_to,_tokenId);
    }
    function implementsERC721() public override  view whenNotPaused returns(bool){
        return erc721Enabled;
    }
    function takeOwnership(uint256 _tokenId) public override whenNotPaused onlyERC721 {
        require(_approved(msg.sender,_tokenId));
        _transfer(tokenIdToOwner[_tokenId],msg.sender,_tokenId);
    }
    function name() public override  pure returns(string  memory _name){
        _name = "Snow";
    }
    function symbol() public override pure returns(string memory _symbol){
        _symbol = "SNY";
    }

    function _owns(address _claimant, uint256 _tokenId) private  view returns(bool){
        return tokenIdToOwner[_tokenId] == _claimant;
    }
    function _approved(address _to, uint256 _tokenId) private  view returns(bool){
        return tokenIdToApproved[_tokenId] == _to;
    }
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        tokenIdToOwner[_tokenId] = _to;

        if(_from != address(0)){
            ownershipTokenCount[_from]--;
            delete tokenIdToApproved[_tokenId];
        }
       emit Transfer(_from, _to, _tokenId);
    }

    function _isContract(address addr) private view returns(bool){
        uint32 size;
        assembly {
        size := extcodesize(addr)
        }
        return (size > 0);
    }

}

