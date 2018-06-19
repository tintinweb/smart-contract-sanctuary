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
        Sold(_ColorId, price, msg.sender); 
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

    function() external payable {
        require(msg.sender == address(0));
    }
}