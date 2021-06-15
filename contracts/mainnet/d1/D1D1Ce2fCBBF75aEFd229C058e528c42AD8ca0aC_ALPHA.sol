/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.6.0;//标明了版本符合标准

    library SafeMath {//安全数值运算库
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
                return 0; 
            }
            uint256 c = a * b;
            assert(c / a == b);
            return c; 
        }
        function div(uint256 a, uint256 b) internal pure returns (uint256) {
// assert(b > 0); // Solidity automatically throws when dividing by 0
            uint256 c = a / b;
// assert(a == b * c + a % b); // There is no case in which this doesn't hold
            return c; 
        }

        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            assert(b <= a);
            return a - b; 
        }
        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            assert(c >= a);
            return c; 
        }
    }

    contract ALPHA {
        using SafeMath for uint;
        string public name; // ERC20 标准
        string public symbol; // ERC20 标准
        uint256 public decimals; // ERC20 标准，decimals 可以有的小数点个数，最小的代币单位。18 是建议的默认值
        uint256 public totalSupply; // ERC20 标准 总供应量
        mapping (address => uint256) public balanceOf;
        mapping (address => mapping (address => uint256)) public allowance;
        event Transfer(address indexed from, address indexed to, uint256 value);
        constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint256 _decimals) public {
            totalSupply = initialSupply * 10 ** _decimals; // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
            balanceOf[msg.sender] = totalSupply; // 创建者拥有所有的代币
            name = tokenName; // 代币名称
            symbol = tokenSymbol; // 代币符号
            decimals = _decimals; 
        }

        function _transfer(address _from, address _to, uint _value) internal {//检测了_to 是否为空地址，但未检测地址_to 和_from 是否为同地址
            require(_to != address(0)&& _from != _to);
            require(balanceOf[_from] >= _value);
            require(balanceOf[_to].add(_value) > balanceOf[_to]);
            uint previousBalances = balanceOf[_from].add(balanceOf[_to]); balanceOf[_from] = balanceOf[_from].sub(_value); balanceOf[_to] = balanceOf[_to].add(_value);
            emit Transfer(_from, _to, _value);
            assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances); 
        }


        function transfer(address _to, uint256 _value) public {
            // require(_to != address(0) && _to != _from); 
            _transfer(msg.sender, _to, _value); 
        }


        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {//显示的返回了 true，检测地址_to 和_from 是否为同地址，检测地址_from 是否为空地址
            require(_value <= allowance[_from][msg.sender]); // Check allowance
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); _transfer(_from, _to, _value);
            return true; 
        }


        function approve(address _spender, uint256 _value) public//不存在交易顺序依赖
            returns (bool success) {
            require(_spender != address(0));
            require((_value == 0) || (allowance[msg.sender][_spender] == 0));
            allowance[msg.sender][_spender] = _value;
            return true; 
        }

        
    }