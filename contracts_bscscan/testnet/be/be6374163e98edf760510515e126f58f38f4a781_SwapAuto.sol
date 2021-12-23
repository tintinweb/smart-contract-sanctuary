/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.7;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


contract SwapAuto is KeeperCompatibleInterface, Ownable {
    // pattern: exchange tokenA for tokenB
    // before use this contract, please put enough tokenA to this contract
    address tokenA = 0x7bF1017dADEe8664Ff533DeF65766bF629C95f46; //Atest
    address tokenB = 0x672eb597C938aaA54fBaFd7e1a783b9Da42af133; //Sushi
    address UniswapRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
    address outReceiver = 0x75aacEeceE0Ed357e43B245554f86629b4902Ad3; //used to receive the tokenB when swap A => B
    uint256 AamountIn;
    uint256 BamountOutMin;

    function setAddress(uint8 _addressID, address _address) external onlyOwner returns(bool) {
        if(_addressID==1){
            tokenA = _address;
        } else if(_addressID==2) {
            tokenB = _address;
        } else if(_addressID==3) {
            UniswapRouter = _address;
        } else if(_addressID==4) {
            outReceiver = _address;
        }else return false;
        return true;
    }

    function setInputParas(uint256 _setAamountIn, uint256 _setBamountOutMin)external onlyOwner returns(bool) {
        AamountIn = _setAamountIn;
        BamountOutMin = _setBamountOutMin;
        return true;
    }

    function setApprove() external {
        uint _value = 100000000*10**18;
        IERC20(tokenA).approve(UniswapRouter,_value);
    }

    function swapTokenAforB(uint _AamountIn, uint _BamountOutMin) public {
        address[] memory _path = new address[](2);
        _path[0] = tokenA;
        _path[1] = tokenB;
        address _to = outReceiver;
        uint _deadline = 1672329600; //2022/12/30
        IUniswapV2Router(UniswapRouter).swapExactTokensForTokens(
            _AamountIn,
            _BamountOutMin,
            _path,
            _to,
            _deadline
        );
    }

    //Called by Chainlink Keepers to check if work needs to be done
    function checkUpkeep(
        bytes calldata /*checkData */
    ) external override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = true;
    }

    //Called by Chainlink Keepers to handle work
    function performUpkeep(bytes calldata) external override {
        swapTokenAforB(AamountIn, BamountOutMin);
    }

    function withdrawExternalToken(address _tokenAddress, address _receiver) external onlyOwner {
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this));
        if(amount > 0){
            IERC20(_tokenAddress).transfer(_receiver,amount);
        }
    }


}