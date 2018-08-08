pragma solidity ^0.4.18;


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
	function name() public view returns (string);
	function symbol() public view returns (string);
	function decimals() public view returns (uint);
    function totalSupply() public view returns (uint);
	function maximumSupply() public view returns (uint);
	
    function balanceOf(address _queryAddress) public constant returns (uint balance);
    function allowance(address _queryAddress, address _approvedAddress) public constant returns (uint remaining);
    function transfer(address _transferAddress, uint _tokenAmount) public returns (bool success);
    function approve(address _approvedAddress, uint _tokenAmount) public returns (bool success);
    function transferFrom(address _fromAddress, address _transferAddress, uint _tokenAmount) public returns (bool success);

    event Transfer(address indexed _fromAddress, address indexed _transferAddress, uint _tokenAmount);
    event Approval(address indexed _fromAddress, address indexed _approvedAddress, uint _tokenAmount);
}


contract PLEXToken is ERC20Interface {
	using SafeMath for uint;
    mapping(address => uint) public balances;
	mapping(address => mapping(address => uint)) public allowed;
	
	string public name;
	string public symbol;
	uint public decimals;
	uint public totalSupply;
	uint public maximumSupply;
	uint public preSaleSupply;
	uint public mainSaleSupply;
	uint public preSaleRate;
	uint public mainSaleRateP1;
	uint public mainSaleRateP2;
	uint public mainSaleRateP3;
	uint public mainSaleRateP4;
	uint public preSaleEnd;
	uint public mainSaleStart;
	uint public mainSaleEnd;
	address public contractOwner;

    constructor() public {
		name = "PLEX";
		symbol = "PLEX";
		decimals = 2;
		totalSupply = 0;
		maximumSupply = 10000000000;
		preSaleSupply = 1000000000;
		mainSaleSupply = 4000000000;
		preSaleRate = 0.0002 ether;
		mainSaleRateP1 = 0.000625 ether;
		mainSaleRateP2 = 0.00071428571 ether;
		mainSaleRateP3 = 0.00083333333 ether;
		mainSaleRateP4 = 0.001 ether;
		preSaleEnd = 1529884800;
		mainSaleStart = 1530554400;
		mainSaleEnd = 1532908800;
		contractOwner = msg.sender;
		
		balances[0xaF3D1767966B8464bEDD88f5B6cFDC23D3Ba7CE3] = 100000000;
		emit Transfer(0, 0xaF3D1767966B8464bEDD88f5B6cFDC23D3Ba7CE3, 100000000);
		
		balances[0x0d958C8f7CCD8d3b03653C3A487Bc11A5db9749B] = 400000000;
		emit Transfer(0, 0x0d958C8f7CCD8d3b03653C3A487Bc11A5db9749B, 400000000);
		
		balances[0x3ca16559A1CC5172d4e524D652892Fb9D422F030] = 500000000;
		emit Transfer(0, 0x3ca16559A1CC5172d4e524D652892Fb9D422F030, 500000000);
		
		balances[0xf231dcadBf45Ab3d4Ca552079FC9B71860CC8255] = 500000000;
		emit Transfer(0, 0xf231dcadBf45Ab3d4Ca552079FC9B71860CC8255, 500000000);
		
		balances[0x38ea72e347232BE550CbF15582056f3259e3A2DF] = 500000000;
		emit Transfer(0, 0x38ea72e347232BE550CbF15582056f3259e3A2DF, 500000000);
		
		balances[0x0e951a73965e373a0ACdFF4Ca6839aB3Aa111061] = 1000000000;
		emit Transfer(0, 0x0e951a73965e373a0ACdFF4Ca6839aB3Aa111061, 1000000000);
		
		balances[0x7Ee2Ec2ECC77Dd7DB791629D5D1aA18f97E7569B] = 1000000000;
		emit Transfer(0, 0x7Ee2Ec2ECC77Dd7DB791629D5D1aA18f97E7569B, 1000000000);
		
		balances[0xF8041851c7E9deB3EA93472F27e9DF872014EcDd] = 1000000000;
		emit Transfer(0, 0xF8041851c7E9deB3EA93472F27e9DF872014EcDd, 1000000000);
		
		totalSupply = totalSupply.add(5000000000);
	}
	
	function name() public constant returns (string) {
		return name;
	}
	
	function symbol() public constant returns (string) {
		return symbol;
	}
	
	function decimals() public constant returns (uint) {
		return decimals;
	}
	
	function totalSupply() public constant returns (uint) {
		return totalSupply;
	}
	
	function maximumSupply() public constant returns (uint) {
		return maximumSupply;
	}
	
	function balanceOf(address _queryAddress) public constant returns (uint balance) {
        return balances[_queryAddress];
    }
	
	function allowance(address _queryAddress, address _approvedAddress) public constant returns (uint remaining) {
        return allowed[_queryAddress][_approvedAddress];
    }
	
	function transfer(address _transferAddress, uint _tokenAmount) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(_tokenAmount);
        balances[_transferAddress] = balances[_transferAddress].add(_tokenAmount);
        emit Transfer(msg.sender, _transferAddress, _tokenAmount);
        return true;
    }
	
	function approve(address _approvedAddress, uint _tokenAmount) public returns (bool success) {
        allowed[msg.sender][_approvedAddress] = _tokenAmount;
        emit Approval(msg.sender, _approvedAddress, _tokenAmount);
        return true;
    }
	
	function transferFrom(address _fromAddress, address _transferAddress, uint _tokenAmount) public returns (bool success) {
        balances[_fromAddress] = balances[_fromAddress].sub(_tokenAmount);
        allowed[_fromAddress][msg.sender] = allowed[_fromAddress][msg.sender].sub(_tokenAmount);
        balances[_transferAddress] = balances[_transferAddress].add(_tokenAmount);
        emit Transfer(_fromAddress, _transferAddress, _tokenAmount);
        return true;
    }
	
	function setDates(uint _preSaleEnd, uint _mainSaleStart, uint _mainSaleEnd) public returns (bool success) {
		require(msg.sender == contractOwner);
		preSaleEnd = _preSaleEnd;
		mainSaleStart = _mainSaleStart;
		mainSaleEnd = _mainSaleEnd;
		return true;
	}
	
	function setPreSaleRate(uint _preSaleRate) public returns (bool success) {
		require(msg.sender == contractOwner);
		preSaleRate = _preSaleRate;
		return true;
	}
    
    function() public payable {
        require((now <= preSaleEnd) || (now >= mainSaleStart && now <= mainSaleEnd));
		if (now <= preSaleEnd) {
			require((msg.value >= 0.01 ether && msg.value <= 15 ether) && (preSaleSupply >= (msg.value / preSaleRate) * 100));
			preSaleSupply = preSaleSupply.sub((msg.value / preSaleRate) * 100);
			totalSupply = totalSupply.add((msg.value / preSaleRate) * 100);
			balances[msg.sender] = balances[msg.sender].add((msg.value / preSaleRate) * 100);
			emit Transfer(0, msg.sender, (msg.value / preSaleRate) * 100);
		}
		if (now >= mainSaleStart && now <= mainSaleEnd) {
			require((msg.value >= 0.01 ether && msg.value <= 15 ether) && (mainSaleSupply >= (msg.value / mainSaleRateP1) * 100));
			if (mainSaleSupply <= 4000000000 && mainSaleSupply > 3000000000) {
				mainSaleSupply = mainSaleSupply.sub((msg.value / mainSaleRateP1) * 100);
				totalSupply = totalSupply.add((msg.value / mainSaleRateP1) * 100);
				balances[msg.sender] = balances[msg.sender].add((msg.value / mainSaleRateP1) * 100);
				emit Transfer(0, msg.sender, (msg.value / mainSaleRateP1) * 100);
			}
			if (mainSaleSupply <= 3000000000 && mainSaleSupply > 2000000000) {
				mainSaleSupply = mainSaleSupply.sub((msg.value / mainSaleRateP2) * 100);
				totalSupply = totalSupply.add((msg.value / mainSaleRateP2) * 100);
				balances[msg.sender] = balances[msg.sender].add((msg.value / mainSaleRateP2) * 100);
				emit Transfer(0, msg.sender, (msg.value / mainSaleRateP2) * 100);
			}
			if (mainSaleSupply <= 2000000000 && mainSaleSupply > 1000000000) {
				mainSaleSupply = mainSaleSupply.sub((msg.value / mainSaleRateP3) * 100);
				totalSupply = totalSupply.add((msg.value / mainSaleRateP3) * 100);
				balances[msg.sender] = balances[msg.sender].add((msg.value / mainSaleRateP3) * 100);
				emit Transfer(0, msg.sender, (msg.value / mainSaleRateP3) * 100);
			}
			if (mainSaleSupply <= 1000000000) {
				mainSaleSupply = mainSaleSupply.sub((msg.value / mainSaleRateP4) * 100);
				totalSupply = totalSupply.add((msg.value / mainSaleRateP4) * 100);
				balances[msg.sender] = balances[msg.sender].add((msg.value / mainSaleRateP4) * 100);
				emit Transfer(0, msg.sender, (msg.value / mainSaleRateP4) * 100);
			}
		}
		contractOwner.transfer(msg.value);
    }
}