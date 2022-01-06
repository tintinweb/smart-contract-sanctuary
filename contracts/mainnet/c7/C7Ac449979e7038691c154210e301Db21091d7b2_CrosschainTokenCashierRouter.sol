/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// File: contracts/token/ERC20Basic.sol

pragma solidity <0.6 >=0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
// File: contracts/token/ERC20.sol

pragma solidity <0.6 >=0.4.21;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/iotube/CrosschainTokenCashierRouter.sol

pragma solidity <6.0 >=0.4.24;


interface ICashier {
    function depositTo(address _token, address _to, uint256 _amount) external payable;
}

interface ICrosschainToken {
    function deposit(uint256 _amount) external;
    function coToken() external view returns (ERC20);
}

contract CrosschainTokenCashierRouter {

    ICashier public cashier;

    constructor(ICashier _cashier) public {
        cashier = _cashier;
    }

    function approveCrosschainToken(address _crosschainToken) public {
        ERC20 token = ICrosschainToken(_crosschainToken).coToken();
        require(safeApprove(address(token), _crosschainToken, uint256(-1)), "failed to approve allowance to crosschain token");
        require(safeApprove(_crosschainToken, address(cashier), uint256(-1)), "failed to approve allowance to cashier");
    }

    function depositTo(address _crosschainToken, address _to, uint256 _amount) public payable {
        require(_crosschainToken != address(0), "invalid token");
        ERC20 token = ICrosschainToken(_crosschainToken).coToken();
        require(safeTransferFrom(address(token), msg.sender, address(this), _amount), "failed to transfer token");
        ICrosschainToken(_crosschainToken).deposit(_amount);
        cashier.depositTo.value(msg.value)(_crosschainToken, _to, _amount);
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        // selector = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')))
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, _from, _to, _amount));
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }

    function safeApprove(address _token, address _spender, uint256 _amount) internal returns (bool) {
        // selector = bytes4(keccak256(bytes('approve(address,uint256)')))
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x095ea7b3, _spender, _amount));
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }
}