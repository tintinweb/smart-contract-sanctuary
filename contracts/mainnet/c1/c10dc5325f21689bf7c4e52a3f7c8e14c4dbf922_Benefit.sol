/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity ^0.4.24;// SPDX-License-Identifier: MIT



//True POZ Token will have this, 
interface IPOZBenefit {
    function IsPOZHolder(address _Subject) external view returns(bool);
}// stakeOf(address account) public view returns (uint256)
// SPDX-License-Identifier: MIT



interface IStaking {
    function stakeOf(address account) public view returns (uint256) ;
}/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}// SPDX-License-Identifier: MIT








contract Benefit is IPOZBenefit, Ownable {
    constructor() public {
        MinHold = 1;
        ChecksCount = 0;
    }

    struct BalanceCheckData {
        bool IsToken; //token or staking contract address
        address ContractAddress; // the address of the token or the staking
        address LpContract; // check the current Token Holdin in Lp
    }

    uint256 public MinHold; //minimum total holding to be POOLZ Holder
    mapping(uint256 => BalanceCheckData) CheckList; //All the contracts to get the sum
    uint256 public ChecksCount; //Total Checks to make

    function SetMinHold(uint256 _MinHold) public onlyOwner {
        require(_MinHold > 0, "Must be more then 0");
        MinHold = _MinHold;
    }

    function AddNewLpCheck(address _Token, address _LpContract)
        public
        onlyOwner
    {
        CheckList[ChecksCount] = BalanceCheckData(false, _Token, _LpContract);
        ChecksCount++;
    }

    function AddNewToken(address _ContractAddress) public onlyOwner {
        CheckList[ChecksCount] = BalanceCheckData(
            true,
            _ContractAddress,
            address(0x0)
        );
        ChecksCount++;
    }

    function AddNewStaking(address _ContractAddress) public onlyOwner {
        CheckList[ChecksCount] = BalanceCheckData(
            false,
            _ContractAddress,
            address(0x0)
        );
        ChecksCount++;
    }

    function RemoveLastBalanceCheckData() public onlyOwner {
        require(ChecksCount > 0, "Can't remove from none");
        ChecksCount--;
    }

    function RemoveAll() public onlyOwner {
        ChecksCount = 0;
    }

    function CheckBalance(address _Token, address _Subject)
        internal
        view
        returns (uint256)
    {
        return ERC20(_Token).balanceOf(_Subject);
    }

    function CheckStaking(address _Contract, address _Subject)
        internal
        view
        returns (uint256)
    {
        return IStaking(_Contract).stakeOf(_Subject);
    }

    function IsPOZHolder(address _Subject) external view returns (bool) {
        return CalcTotal(_Subject) >= MinHold;
    }

    function CalcTotal(address _Subject) public view returns (uint256) {
        uint256 Total = 0;
        for (uint256 index = 0; index < ChecksCount; index++) {
            if (CheckList[index].LpContract == address(0x0)) {
                Total =
                    Total +
                    (
                        CheckList[index].IsToken
                            ? CheckBalance(
                                CheckList[index].ContractAddress,
                                _Subject
                            )
                            : CheckStaking(
                                CheckList[index].ContractAddress,
                                _Subject
                            )
                    );
            } else {
                Total =
                    Total +
                    _CalcLP(
                        CheckList[index].LpContract,
                        CheckList[index].ContractAddress,
                        _Subject
                    );
            }
        }
        return Total;
    }

    function _CalcLP(
        address _Contract,
        address _Token,
        address _Subject
    ) internal view returns (uint256) {
        uint256 TotalLp = ERC20(_Contract).totalSupply();
        uint256 SubjectLp = ERC20(_Contract).balanceOf(_Subject);
        uint256 TotalTokensOnLp = ERC20(_Token).balanceOf(_Contract);
        //SubjectLp * TotalTokensOnLp / TotalLp
        return SafeMath.div(SafeMath.mul(SubjectLp, TotalTokensOnLp), TotalLp);
    }
}