// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

    /**************************************************************************
    * Interfaces & Libraries
    ***************************************************************************/
    import "IERC165.sol";
    import "IERC721.sol";
    import "IERC721Receiver.sol";
    import "Address.sol";
    import "Ownable.sol";

    contract SocialPixel is IERC165, IERC721, IERC721Receiver, Ownable {
    using Address for address;

    struct Pixel {
        string message;
        uint256 price;
        bool isSale;
    }


    /**************************************************************************
    * public variables
    ***************************************************************************/
    uint32[10000] public colors; //colors are encoded as rgb in the follow format: 1rrrgggbbb. For example, red is 1255000000.


    /**************************************************************************
    * private variables
    ***************************************************************************/
    //mapping from token ID to Pixel struct
    mapping (uint256 => Pixel) private pixelNumberToPixel;
    
    //mapping from token ID to owner
    mapping (uint256 => address) private pixelNumberToOwner;
    
    //mapping from token ID to approved address
    mapping (uint256 => address) private pixelNumberToApproved;
    
    //mapping from owner to number of owned token
    mapping (address => uint256) private ownerToPixelAmount;
    
    //mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private ownerToOperatorToBool;
    
    //mapping of supported interfaces
    mapping(bytes4 => bool) internal supportedInterfaces;




    /**************************************************************************
    * public constants
    ***************************************************************************/
    uint256 public constant numberOfPixels = 10000;
    uint256 public constant feeRate = 100;




    /**************************************************************************
    * private constants
    ***************************************************************************/
    uint256 private defaultWeiPrice = 10000000000000000;   // 0.01 eth
    



    /**************************************************************************
    * modifiers
    ***************************************************************************/
    modifier onlyPixelOwner(uint256 _pixelNumber) {
        require(msg.sender == pixelNumberToOwner[_pixelNumber]);
        _;
    }
    
    modifier validPixel(uint256 _pixelNumber) {
        require(_pixelNumber < numberOfPixels);
        _;
    }
    
    modifier validColor(uint32 _color) {
        require(_color >= 1000000000 && _color <= 1255255255);
        _;
    }



    /**************************************************************************
    * constructor
    ***************************************************************************/
    constructor() {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        ownerToPixelAmount[owner()] = numberOfPixels;
    }



    /**************************************************************************
    * public methods
    ***************************************************************************/
    function getPixel(uint256 _pixelNumber) 
        public view validPixel(_pixelNumber)
        returns(address, string memory, uint256, bool) 
    {
        address pixelOwner = pixelNumberToOwner[_pixelNumber]; 
        
        if (pixelOwner == address(0)) {
            return (owner(), "", defaultWeiPrice, true);
        }
        
        Pixel memory pixel;
        pixel = pixelNumberToPixel[_pixelNumber];
        return (pixelOwner, pixel.message, pixel.price, pixel.isSale);
    }
    
    function getColors() public view returns(uint32[10000] memory)  {
        return colors;
    }

    function buyPixel(uint256 _pixelNumber, uint32 _color, string memory _message)
        payable
        public validColor(_color)
    {
        require(msg.sender != address(0));
        
        address currentOwner;
        uint256 currentPrice;
        bool currentSaleState;
        (currentOwner,,currentPrice, currentSaleState) = getPixel(_pixelNumber);
        
        require(currentSaleState == true);

        require(currentPrice <= msg.value);

        uint fee = msg.value / feeRate;

        payable(currentOwner).transfer(msg.value - fee);

        pixelNumberToPixel[_pixelNumber] = Pixel(_message, currentPrice, false);
        
        colors[_pixelNumber] = _color;
        changeAdjacentColors(_pixelNumber, _color);

        transfer(msg.sender, _pixelNumber);
    }
    
    function setColor(uint256 _pixelNumber, uint32 _color) 
        public validPixel(_pixelNumber) validColor(_color)
        onlyPixelOwner(_pixelNumber)
    {
        colors[_pixelNumber] = _color;
        changeAdjacentColors(_pixelNumber, _color);
    }


    function setMessage(uint256 _pixelNumber, string memory _message)
        public validPixel(_pixelNumber)
        onlyPixelOwner(_pixelNumber)
    {
        pixelNumberToPixel[_pixelNumber].message = _message;
    }


    function setPrice(uint256 _pixelNumber, uint256 _weiAmount) 
        public validPixel(_pixelNumber)
        onlyPixelOwner(_pixelNumber)
    {
        pixelNumberToPixel[_pixelNumber].price = _weiAmount;
    }


    function setForSale(uint256 _pixelNumber)
        public validPixel(_pixelNumber)
        onlyPixelOwner(_pixelNumber)
    {
        pixelNumberToPixel[_pixelNumber].isSale = true;
    }
    
    function setNotForSale(uint256 _pixelNumber)
        public validPixel(_pixelNumber)
        onlyPixelOwner(_pixelNumber)
    {
        pixelNumberToPixel[_pixelNumber].isSale = false;
    }



    /**************************************************************************
    * internal methods
    ***************************************************************************/
    function changeAdjacentColors(uint256 _pixelNumber, uint32 _color) internal {
        
        uint256 i;
        uint256 j;
        
        if (_pixelNumber >= 0 && _pixelNumber < 100) { 
            if (_pixelNumber == 0) {
                j = 3;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            } else if (_pixelNumber == 99) {
                j = 5;
                i = 2;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            } else {
                j = 5;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            }
        } else if (_pixelNumber % 100 == 99) { 
            if (_pixelNumber == 9999) {
                i = 4;
                j = 7;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            } else {
                i = 2;
            j = 7;
            _changeAdjacentColors(i, j, _pixelNumber, _color);
            return;
            }
            
        } else if (_pixelNumber >= 9900 && _pixelNumber < 10000 ) { 
            if (_pixelNumber == 9900) {
                i = 6;
                j = 9;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            } else {
                i = 4;
                j = 9;
                _changeAdjacentColors(i, j, _pixelNumber, _color);
                return;
            }
        } else if (_pixelNumber % 100 == 0) {
            i = 6;
            j = 11;
            _changeAdjacentColors(i, j, _pixelNumber, _color);
            return;
        } else {
            j = 8;
            _changeAdjacentColors(i, j, _pixelNumber, _color);
            return;
        }  
    }

    function _changeAdjacentColors(uint256 i, uint256 j, uint256 _pixelNumber, uint32 color) internal {
        
        int256[16] memory offSets = [int256(1), 101, 100, 99, -1, -101, -100, -99, 1, 101, 100, 99, -1, -101, -100, -99];
        
        for (uint256 x = i; x < j; x++) {
            int256 adjPixel = int256(_pixelNumber) + offSets[x];
            colors[uint256(adjPixel)] = mixColors(color, colors[uint256(adjPixel)]);
        }
        
    }
    
    function mixColors(uint32 c0, uint32 c1) internal pure returns (uint32) {
        return 1000000000 + (((c0 / 1000000) % 1000) + ((c1 / 1000000) % 1000))/2*1000000 + (((c0 / 1000) % 1000) + ((c1 / 1000) % 1000))/2*1000 + ((c0 % 1000) + (c1 % 1000))/2;
    }

    /**************************************************************************
    * methods for contract owner
    ***************************************************************************/

    function withdrawBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function setDefaultPrice(uint256 _price) external onlyOwner {
        defaultWeiPrice = _price;
    }

    /**************************************************************************
    * ERC-721 compliance
    ***************************************************************************/

    //Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    //ERC-721 implementation
    function balanceOf(address _owner) external override view returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");

        return ownerToPixelAmount[_owner];
    }

    function ownerOf(uint256 _pixelNumber) external override view returns (address) {
        address owner;
        (owner,,,) = getPixel(_pixelNumber);
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _pixelNumber, bytes calldata data) external override  {
        address tokenOwner = pixelNumberToOwner[_pixelNumber];
        require(msg.sender == tokenOwner || msg.sender == pixelNumberToApproved[_pixelNumber] || ownerToOperatorToBool[tokenOwner][msg.sender],
                "ERC721: message sender is not the owner or approved address");
        require(_from == tokenOwner);
        require(_to != address(0));
        require(tokenOwner != address(0));
        transfer(_to, _pixelNumber);
        if (_to.isContract()) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _pixelNumber, data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _pixelNumber) external override  {
        address tokenOwner = pixelNumberToOwner[_pixelNumber];
        require(msg.sender == tokenOwner || msg.sender == pixelNumberToApproved[_pixelNumber] || ownerToOperatorToBool[tokenOwner][msg.sender],
                "ERC721: message sender is not the owner or approved address");
        require(_from == tokenOwner);
        require(_to != address(0));
        require(tokenOwner != address(0));
        transfer(_to, _pixelNumber);
        if (_to.isContract()) {
            bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _pixelNumber, "");
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function transferFrom(address _from, address _to, uint256 _pixelNumber) external override {
        address tokenOwner = pixelNumberToOwner[_pixelNumber];
        require(msg.sender == tokenOwner ||
                msg.sender == pixelNumberToApproved[_pixelNumber] ||
                ownerToOperatorToBool[tokenOwner][msg.sender]);
        require(_from == tokenOwner);
        require(_to != address(0));
        require(tokenOwner != address(0));
        transfer(_to, _pixelNumber);
    }

    function approve(address _approved, uint256 _pixelNumber) external override {
        address tokenOwner = pixelNumberToOwner[_pixelNumber];
        require(msg.sender == tokenOwner ||
                msg.sender == pixelNumberToApproved[_pixelNumber] ||
                ownerToOperatorToBool[tokenOwner][msg.sender]);
        pixelNumberToApproved[_pixelNumber] = _approved;

        emit Approval(tokenOwner, _approved, _pixelNumber);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender);

        ownerToOperatorToBool[msg.sender][_operator] = _approved;
        
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _pixelNumber) external override view returns (address) {
        address owner = pixelNumberToOwner[_pixelNumber];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return pixelNumberToApproved[_pixelNumber];
    }

    function isApprovedForAll(address _owner, address _operator) external override view returns (bool) {
        return ownerToOperatorToBool[_owner][_operator];
    }

    function supportsInterface(bytes4 _interfaceID) external override view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override pure external returns (bytes4) {
         return MAGIC_ON_ERC721_RECEIVED;
    }

    //ERC-721 implementation helper functions
    function transfer(address _to, uint256 _pixelNumber) internal {
        address from;
        (from,,,) = getPixel(_pixelNumber);
        clearApproval(_pixelNumber);

        removeToken(from, _pixelNumber);
        addToken(_to, _pixelNumber);

        emit Transfer(from, _to, _pixelNumber);
    }

    function clearApproval(uint256 _pixelNumber) private {
        if (pixelNumberToApproved[_pixelNumber] != address(0)) {
            delete pixelNumberToApproved[_pixelNumber];
        }
    }

    function removeToken(address _from, uint256 _pixelNumber) internal {
        ownerToPixelAmount[_from] = ownerToPixelAmount[_from] - 1;
        delete pixelNumberToOwner[_pixelNumber];
    }

    function addToken(address _to, uint256 _pixelNumber) internal {
        require(pixelNumberToOwner[_pixelNumber] == address(0));

        pixelNumberToOwner[_pixelNumber] = _to;
        ownerToPixelAmount[_to] = ownerToPixelAmount[_to] + 1;
    }

}