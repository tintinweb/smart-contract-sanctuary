/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

pragma solidity =0.5.12;

contract BinhePay{
    
    string public name;
    string public symbol;
    uint8 public decimals = 4;
    uint256 public totalSupply;
    address internal admin;
    mapping (address => uint256) public balanceOf;
    bool public isActivity = true;
    bool public openRaise = true;
    uint256 public raiseOption = 0;
    address payable internal management;
    
	event Transfer(address indexed from, address indexed to, uint256 value);
	event SendEth(address indexed to, uint256 value);
    
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
     ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        management = msg.sender;
        admin = msg.sender;
    }

    modifier onlyAdmin() { 
        require(msg.sender == admin);
        _;
    }

    modifier isAct() { 
        require(isActivity);
        _;
    }

    modifier isOpenRaise() { 
        require(openRaise);
        _;
    }

    function () external payable isAct isOpenRaise{
		require(raiseOption >= 0);
		uint256 buyNum = msg.value /10000 * raiseOption;
		require(buyNum <= balanceOf[management]);
		balanceOf[management] -= buyNum;
		balanceOf[msg.sender] += buyNum;
        management.transfer(msg.value);
        emit SendEth(management, msg.value);
        emit Transfer(management, msg.sender, buyNum);
	}
    
    function transfer(address _to, uint256 _value) public isAct{
	    _transfer(msg.sender, _to, _value);
    }
    
    function batchTransfer(address[] memory _tos, uint[] memory _values) public isAct {
        require(_tos.length == _values.length);
        uint256 _total = 0;
        for(uint256 i;i<_values.length;i++){
            _total += _values[i];
	    }
        require(balanceOf[msg.sender]>=_total);
        for(uint256 i;i<_tos.length;i++){
            _transfer(msg.sender,_tos[i],_values[i]);
	    }
    }
    
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
	
	function mint(address usr, uint wad) external onlyAdmin {
        balanceOf[usr] = balanceOf[usr] + wad;
        totalSupply    = totalSupply + wad;
        emit Transfer(address(0), usr, wad);
    }
	
	function setRaiseOption(uint256 _price)public onlyAdmin{
		raiseOption = _price;
	}
	
	function setRaiseOpen(bool _open) public onlyAdmin{
	    openRaise = _open;
	}
	
	function setAct(bool _isAct) public onlyAdmin{
		isActivity = _isAct;
	}
	
	function changeAdmin(address _address) public onlyAdmin{
       admin = _address;
    }
    
    function changeFinance(address payable _address) public onlyAdmin{
       management = _address;
    }
	
	function destructContract()public onlyAdmin{
		selfdestruct(management);
	}
	
}