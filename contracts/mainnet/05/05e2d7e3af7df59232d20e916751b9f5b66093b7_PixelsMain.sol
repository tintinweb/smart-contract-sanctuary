pragma solidity ^0.4.11;

contract Ownable {

  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    owner = newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

contract ColorsData is Ownable {

    struct Color {
	    string label;
		uint64 creationTime;
    }

	event Transfer(address from, address to, uint256 colorId);
    event Sold(uint256 colorId, uint256 priceWei, address winner);
	
    Color[] colors;

    mapping (uint256 => address) public ColorIdToOwner;
    mapping (uint256 => uint256) public ColorIdToLastPaid;
    
}

contract ColorsApis is ColorsData {

    function getColor(uint256 _id) external view returns (string label, uint256 lastPaid, uint256 price) {
        Color storage color1 = colors[_id];
		label = color1.label;
        lastPaid = ColorIdToLastPaid[_id];
		price = lastPaid + ((lastPaid * 2) / 10);
    }

    function registerColor(string label, uint256 startingPrice) external onlyOwner {        
        Color memory _Color = Color({
		    label: label,
            creationTime: uint64(now)
        });

        uint256 newColorId = colors.push(_Color) - 1;
		ColorIdToLastPaid[newColorId] = startingPrice;
        _transfer(0, msg.sender, newColorId);
    }
    
    function transfer(address _to, uint256 _ColorId) external {
        require(_to != address(0));
        require(_to != address(this));
        require(ColorIdToOwner[_ColorId] == msg.sender);
        _transfer(msg.sender, _to, _ColorId);
    }

    function ownerOf(uint256 _ColorId) external view returns (address owner) {
        owner = ColorIdToOwner[_ColorId];
        require(owner != address(0));
    }
        
    function bid(uint256 _ColorId) external payable {
        uint256 lastPaid = ColorIdToLastPaid[_ColorId];
        require(lastPaid > 0);
		
		uint256 price = lastPaid + ((lastPaid * 2) / 10);
        require(msg.value >= price);
		
		address colorOwner = ColorIdToOwner[_ColorId];
		uint256 colorOwnerPayout = lastPaid + (lastPaid / 10);
        colorOwner.transfer(colorOwnerPayout);
		
		// Transfer whatever is left to owner
        owner.transfer(msg.value - colorOwnerPayout);
		
		ColorIdToLastPaid[_ColorId] = msg.value;
		ColorIdToOwner[_ColorId] = msg.sender;

		// Trigger sold event
        Sold(_ColorId, msg.value, msg.sender); 
    }

    function _transfer(address _from, address _to, uint256 _ColorId) internal {
        ColorIdToOwner[_ColorId] = _to;        
        Transfer(_from, _to, _ColorId);
    }
}

contract ColorsMain is ColorsApis {

    function ColorsMain() public payable {
        owner = msg.sender;
    }
    
    function createStartingColors() external onlyOwner {
        require(colors.length == 0);
        this.registerColor("Red", 1);
    }
    
    function() external payable {
        require(msg.sender == address(0));
    }
    
}

contract PixelsData is Ownable {

    struct Pixel {
        address currentOwner;
        uint256 lastPricePaid;
		uint64 lastUpdatedTime;
    }

    event Sold(uint256 x, uint256 y, uint256 colorId, uint256 priceWei, address winner);
	
    mapping (uint256 => Pixel) public PixelKeyToPixel;
    
    ColorsMain colorsMain;
    
    uint256 startingPriceWei = 5000000000000000;
}

contract PixelsApi is PixelsData {
    
    function bidBatch(uint256[] inputs, address optionlReferrer) external payable {
        require(inputs.length > 0);
        require(inputs.length % 3 == 0);        
        
        uint256 rollingPriceRequired = 0;
        
        for(uint256 i = 0; i < inputs.length; i+=3)
        {
            uint256 x = inputs[i];
            uint256 y = inputs[i+1];
        
            uint256 lastPaid = startingPriceWei;
            uint256 pixelKey =  x + (y * 10000000);
            Pixel storage pixel = PixelKeyToPixel[pixelKey];
            
            if(pixel.lastUpdatedTime != 0) {
                lastPaid = pixel.lastPricePaid;
            }
    		
    		rollingPriceRequired += lastPaid + ((lastPaid * 2) / 10);
        }
        
        require(msg.value >= rollingPriceRequired);
        
        for(uint256 z = 0; z < inputs.length; z+=3)
        {
            uint256 x1 = inputs[z];
            uint256 y1 = inputs[z+1];
            uint256 colorId = inputs[z+2];
            bid(x1, y1, colorId, optionlReferrer);
        }
    }
    
    function bid(uint256 x, uint256 y, uint256 colorId, address optionlReferrer) internal {
        uint256 lastPaid = startingPriceWei;
        address currentOwner = owner;
        uint256 pixelKey =  x + (y * 10000000);
        
        Pixel storage pixel = PixelKeyToPixel[pixelKey];
        
        if(pixel.lastUpdatedTime != 0) {
            lastPaid = pixel.lastPricePaid;
            currentOwner = pixel.currentOwner;
        }
		
		uint256 price = lastPaid + ((lastPaid * 2) / 10);
        require(msg.value >= price);
        
        address colorOwner;
        
        if(colorId == 99999) { //white
            colorOwner = owner;
        } else {
            colorOwner = colorsMain.ownerOf(colorId);
        }
        
		require(colorOwner != 0);
		
		uint256 currentOwnerPayout = lastPaid + (lastPaid / 10);
        currentOwner.transfer(currentOwnerPayout);
        
		uint256 remainingPayout = price - currentOwnerPayout;
		uint256 colorOwnersFee = remainingPayout / 2;
        colorOwner.transfer(colorOwnersFee);
        
        uint256 referralFee = 0;
        
        if(optionlReferrer != 0) {
            referralFee = colorOwnersFee / 2;
            optionlReferrer.transfer(referralFee);
        }
        
        owner.transfer(colorOwnersFee - referralFee);
        
        Pixel memory _Pixel = Pixel({
            currentOwner: msg.sender,
		    lastPricePaid: price,
            lastUpdatedTime: uint64(now)
        });

        PixelKeyToPixel[pixelKey] = _Pixel;

        Sold(x, y, colorId, price, msg.sender); 
    }
    
    function setColorContract(address colorContract) external onlyOwner {        
        colorsMain = ColorsMain(colorContract);
    }
    
}

contract PixelsMain is PixelsApi {
 
    function PixelsMain() public payable {
        owner = msg.sender;
    }

    function() external payable {
        require(msg.sender == address(0));
    }

}