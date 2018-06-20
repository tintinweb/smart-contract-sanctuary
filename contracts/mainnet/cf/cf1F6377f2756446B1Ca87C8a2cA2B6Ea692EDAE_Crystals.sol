pragma solidity ^0.4.24;

// written by madgustave from Team Chibi Fighters
// find us at https://chibigame.io
// info@chibifighters.io
// version 1.0.0

contract ExternalTokensSupport {
    function calculateAmount(address, uint256, address, bytes, uint256) public pure returns(uint256, uint256, uint256) {}
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


interface ERC20Interface {
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external;
    function balanceOf(address _owner) external view returns (uint256 _balance);
}

interface ERC20InterfaceClassic {
    function transfer(address to, uint tokens) external returns (bool success);
}

contract Crystals is Owned {
	// price of one crystal in wei
	uint256 public crystalPrice;
    ExternalTokensSupport public etsContract;    

	event crystalsBought(
		address indexed buyer,
		uint256 amount,
        uint256 indexed paymentMethod 
	);

	constructor(uint256 startPrice, address etsAddress) public {
		crystalPrice = startPrice;
        etsContract = ExternalTokensSupport(etsAddress);
	}

	function () public payable {
		require(msg.value >= crystalPrice);

		// crystal is indivisible
		require(msg.value % crystalPrice == 0);

		emit crystalsBought(msg.sender, msg.value / crystalPrice, 0);
	}

    function buyWithERC20(address _sender, uint256 _value, ERC20Interface _tokenContract, bytes _extraData) internal {
        require(etsContract != address(0));

        (uint256 crystalsAmount, uint256 neededTokensAmount, uint256 paymentMethod) = etsContract.calculateAmount(_sender, _value, _tokenContract, _extraData, crystalPrice);

        require(_tokenContract.transferFrom(_sender, address(this), neededTokensAmount));

        emit crystalsBought(_sender, crystalsAmount, paymentMethod);
    }

    function receiveApproval(address _sender, uint256 _value, ERC20Interface _tokenContract, bytes _extraData) public {
        buyWithERC20(_sender, _value, _tokenContract, _extraData);
    }

	function changePrice(uint256 newPrice) public onlyOwner {
		crystalPrice = newPrice;
	}

    function changeEtsAddress(address etsAddress) public onlyOwner {
        etsContract = ExternalTokensSupport(etsAddress);
    }

    /**
    * @dev Send Ether to owner
    * @param _address Receiving address
    * @param _amountWei Amount in WEI to send
    **/
    function weiToOwner(address _address, uint _amountWei) public onlyOwner returns (bool) {
        require(_amountWei <= address(this).balance);
        _address.transfer(_amountWei);
        return true;
    }

    function ERC20ToOwner(address _to, uint256 _amount, ERC20Interface _tokenContract) public onlyOwner {
        _tokenContract.transfer(_to, _amount);
    }

    function ERC20ClassicToOwner(address _to, uint256 _amount, ERC20InterfaceClassic _tokenContract) public onlyOwner {
        _tokenContract.transfer(_to, _amount);
    }
    
    function queryERC20(ERC20Interface _tokenContract) public view onlyOwner returns (uint) {
        return _tokenContract.balanceOf(this);
    }
}