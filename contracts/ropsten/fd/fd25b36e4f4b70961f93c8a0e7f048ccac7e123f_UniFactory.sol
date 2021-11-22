/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity =0.8.10;

interface IUniPair{
    
    function initialize(address token0,address token1) external;
    
    function swap(int256 _amountIn,int256 _amountMinOut,address pairAddress,address swapInAddress,address swapOutAddress) external;
    
}

pragma solidity =0.8.10;

contract UniPair is IUniPair{
    
    address public token0;
    address public token1;
    
    uint public totalSupply;
    mapping(address=>uint) public balanceOf;
    
    
     function initialize(address _token0,address _token1) external{
         token0=_token0;
         token1=_token1;
     }
     
     function swap(int256 _amountIn,int256 _amountMinOut,address pairAddress,address swapInAddress,address swapOutAddress) external{
        //传入金额
        (bool success, bytes memory data) = swapInAddress.call(abi.encodeWithSelector(0x23b872dd, msg.sender, pairAddress, _amountIn));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
        //swap out money
        (bool success2, bytes memory data2) = swapOutAddress.call(abi.encodeWithSelector(0x23b872dd, pairAddress,msg.sender , _amountMinOut));
        require(
            success2 && (data2.length == 0 || abi.decode(data2, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
        
     }
     
     
     function addLiquidity(int256 _token1Amount,int256 _token2Amount,address token1Address,address token2Address,address swapOutAddress) external{
     
        address pairAddress=token0;
        // add token0
        (bool success, bytes memory data) = token1Address.call(abi.encodeWithSelector(0x23b872dd, msg.sender, pairAddress, _token1Amount));
        // add token1
        (bool success1, bytes memory data1) = token2Address.call(abi.encodeWithSelector(0x23b872dd, msg.sender, pairAddress, _token2Amount));
        //mint token
        totalSupply=totalSupply+1;
        balanceOf[msg.sender]=balanceOf[msg.sender]+1;
        
     }
     
     
     
}

pragma solidity =0.8.10;


contract UniFactory{
    
    function createPair(address token0,address token1)  external returns (address pair) {
        bytes memory bytecode = type(UniPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniPair(pair).initialize(token0, token1);
    }
}