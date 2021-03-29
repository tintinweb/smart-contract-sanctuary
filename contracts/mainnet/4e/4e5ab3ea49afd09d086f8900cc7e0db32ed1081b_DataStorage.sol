/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

pragma solidity 0.6.12;


    abstract contract Context {
            function _msgSender() internal view virtual returns (address payable) {
                return msg.sender;
            }
    
            function _msgData() internal view virtual returns (bytes memory) {
                this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
                return msg.data;
            }
        }
    contract Ownable is Context {
        address private _owner;
    
        event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
        /**
        * @dev Initializes the contract setting the deployer as the initial owner.
        */
        constructor () internal {
            address msgSender = _msgSender();
            _owner = msgSender;
            emit OwnershipTransferred(address(0), msgSender);
        }
    
        /**
        * @dev Returns the address of the current owner.
        */
        function owner() public view returns (address) {
            return _owner;
        }
    
        /**
        * @dev Throws if called by any account other than the owner.
        */
        modifier onlyOwner() {
            require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
            emit OwnershipTransferred(_owner, address(0));
            _owner = address(0);
        }
    
        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
        */
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }
    }


    contract DataStorage is Ownable{
       
        uint256 constant feeAdjusted = 10000;
        struct PoolInfo{
            address lpToken;
            address stakingPool;
        }

        PoolInfo[] public poolInfo;
        

        constructor() public {
        poolInfo.push(PoolInfo({
                lpToken: 0x93567318aaBd27E21c52F766d2844Fc6De9Dc738,
                stakingPool: 0x103cc17C2B1586e5Cd9BaD308690bCd0BBe54D5e})); 
        poolInfo.push(PoolInfo({
                lpToken: 0x479A8666Ad530af3054209Db74F3C74eCd295f8D,
                stakingPool: 0x4B2e76EbBc9f2923d83F5FBDe695D8733db1a17B}));
        poolInfo.push(PoolInfo({
                lpToken: 0xd59996055b5E0d154f2851A030E207E0dF0343B0,
                stakingPool: 0x0C49066C0808Ee8c673553B7cbd99BCC9ABf113d}));
        }

        function poolLength() external view returns (uint256) {
            return poolInfo.length;
        }

        function add(address _lpToken, address _stakingPool) public onlyOwner {
            poolInfo.push(PoolInfo({
                lpToken: _lpToken,
                stakingPool: _stakingPool})); 
        }
    }