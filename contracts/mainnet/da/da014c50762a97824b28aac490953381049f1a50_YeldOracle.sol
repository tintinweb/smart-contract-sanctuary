pragma solidity 0.5.17;

interface IYeldContract {
  function rebalance() external;
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address payable) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract YeldOracle is Ownable {
  address public yDAI;
  address public yTether;
  address public yTrueUSD;
  address public yUSDC;

  function () external payable {}

  constructor (address _yDAI, address _yTether, address _yTrueUSD, address _yUSDC) public {
    yDAI = _yDAI;
    yTether = _yTether;
    yTrueUSD = _yTrueUSD;
    yUSDC = _yUSDC;
    rebalance();
  }

  function extractTokensIfStuck(address _token, uint256 _amount) public onlyOwner {
    IERC20(_token).transfer(msg.sender, _amount);
  }

  function extractETHIfStuck() public onlyOwner {
    owner().transfer(address(this).balance);
  }

  function setyDAI(address _contract) public onlyOwner {
    yDAI = _contract;
  }

  function setyTether(address _contract) public onlyOwner {
    yTether = _contract;
  }

  function setyTrueUSD(address _contract) public onlyOwner {
    yTrueUSD = _contract;
  }

  function setyUSDC(address _contract) public onlyOwner {
    yUSDC = _contract;
  }

  function rebalance() public {
    IYeldContract(yDAI).rebalance();
    IYeldContract(yTether).rebalance();
    IYeldContract(yTrueUSD).rebalance();
    IYeldContract(yUSDC).rebalance();
  }
}