/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract AtomicTypes{
    struct SwapParams{
        Token sellToken; 
        uint256 input;
        Token buyToken;
        uint minOutput;
    }
    
    struct DistributionParams{
        IAtomicExchange[] exchangeModules;
        bytes[] exchangeData;
        uint256[] chunks;
    }
    
    event Trade(
        address indexed sellToken,
        uint256 sellAmount,
        address indexed buyToken,
        uint256 buyAmount,
        address indexed trader,
        address receiver
    );
}

contract AtomicUtils{    
    // ETH and its wrappers
    address constant WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWETH constant WETH = IWETH(WETHAddress);
    Token constant ETH = Token(address(0));
    address constant EEEAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    Token constant EEE = Token(EEEAddress);
    
    // Universal function to query this contracts balance, supporting  and Token
    function balanceOf(Token token) internal view returns(uint balance){
        if(isETH(token)){
            return address(this).balance;
        }else{
            return token.balanceOf(address(this));
        }
    }
    
    // Universal send function, supporting ETH and Token
    function send(Token token, address payable recipient, uint amount) internal {
        if(isETH(token)){
            require(
                recipient.send(amount),
                "Sending of ETH failed."
            );
        }else{
            Token(token).transfer(recipient, amount);
            require(
                validateOptionalERC20Return(),
                "ERC20 token transfer failed."
            );
        }
    }
    
    // Universal function to claim tokens from msg.sender
    function claimTokenFromSenderTo(Token _token, uint _amount, address _receiver) internal {
        if (isETH(_token)) {
            require(msg.value == _amount);
            // dont forward ETH
        }else{
            require(msg.value  == 0);
            _token.transferFrom(msg.sender, _receiver, _amount);
        }
    }
    
    // Token approval function supporting non-compliant tokens
    function approve(Token _token, address _spender, uint _amount) internal {
        if (!isETH(_token)) {
            _token.approve(_spender, _amount);
            require(
                validateOptionalERC20Return(),
                "ERC20 approval failed."
            );
        }
    }
    
    // Validate return data of non-compliant erc20s
    function validateOptionalERC20Return() pure internal returns (bool){
        uint256 success = 0;

        assembly {
            switch returndatasize()             // Check the number of bytes the token contract returned
            case 0 {                            // Nothing returned, but contract did not throw > assume our transfer succeeded
                success := 1
            }
            case 32 {                           // 32 bytes returned, result is the returned bool
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
        }

        return success != 0;
    }

    function isETH(Token token) pure internal  returns (bool){
        if(
            address(token) == address(0)
            || address(token) == EEEAddress
        ){
            return true;
        }else{
            return false;
        }
    }

    function isWETH(Token token) pure internal  returns (bool){
        if(address(token) == WETHAddress){
            return true;
        }else{
            return false;
        }
    }
    
    // Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function sliceBytes(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length), "Read out of bounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}


abstract contract IAtomicExchange is AtomicTypes{
    function swap(
        SwapParams memory _swap,
        bytes memory data
    )  external payable virtual returns(
        uint output
    );
}

contract AtomicBlue is AtomicUtils, AtomicTypes{
    // IMPORTANT NOTICE:
    // NEVER set a token allowance to this contract, as everybody can do arbitrary calls from it.
    // When swapping tokens always go through AtomicTokenProxy.
    // This contract assumes token to swap has already been transfered to it when being called. Ether can be sent directly with the call.

    // perform a distributed swap and transfer outcome to _receipient
    function swapAndSend(
        SwapParams memory _swap,
        
        DistributionParams memory _distribution,
        
        address payable _receipient
    ) public payable returns (uint _output){
        // execute swaps on behalf of trader
        _output = doDistributedSwap(_swap, _distribution);

        // check if output of swap is sufficient        
        require(_output >= _swap.minOutput, "Slippage limit exceeded.");
        
        // send swap output to receipient
        send(_swap.buyToken, _receipient, _output);
        
        emit Trade(
            address(_swap.sellToken),
            _swap.input,
            address(_swap.buyToken),
            _output,
            msg.sender,
            _receipient
        );
    }
    
    function multiPathSwapAndSend(
        SwapParams memory _swap,
        
        Token[] calldata _path,
        
        DistributionParams[] memory _distribution,
        
        address payable _receipient
    ) public payable returns (uint _output){
        // verify path
        require(
            _path[0] == _swap.sellToken
            && _path[_path.length - 1] == _swap.buyToken
            && _path.length >= 2
        );
        
        // execute swaps on behalf of trader
        _output = _swap.input;
        for(uint i = 1; i < _path.length; i++){
            _output = doDistributedSwap(SwapParams({
                sellToken : _path[i - 1],
                input     : _output,      // output of last swap is input for this one
                buyToken  : _path[i],
                minOutput : 0            // we check the total outcome in the end
            }), _distribution[i - 1]);
        }

        // check if output of swap is sufficient        
        require(_output >= _swap.minOutput, "Slippage limit exceeded.");
        
        // send swap output to sender
        send(_swap.buyToken, _receipient, _output);
        
        emit Trade(
            address(_swap.sellToken),
            _swap.input,
            address(_swap.buyToken),
            _output,
            msg.sender,
            _receipient
        );
    }
    
    
    // internal function to perform a distributed swap
    function doDistributedSwap(
        SwapParams memory _swap,
        
        DistributionParams memory _distribution
    ) internal returns(uint){
        
        // count totalChunks
        uint totalChunks = 0;
        for(uint i = 0; i < _distribution.chunks.length; i++){
            totalChunks += _distribution.chunks[i];   
        }
        
        // route trades to the different exchanges
        for(uint i = 0; i < _distribution.exchangeModules.length; i++){
            IAtomicExchange exchange = _distribution.exchangeModules[i];
            
            uint thisInput = _swap.input * _distribution.chunks[i] / totalChunks;
            
            if(address(exchange) == address(0)){
                // trade is not using an exchange module but a direct call
                (address target, uint value, bytes memory callData) = abi.decode(_distribution.exchangeData[i], (address, uint, bytes));
                
                (bool success, bytes memory data) = address(target).call.value(value)(callData);
            
                require(success, "Exchange call reverted.");
            }else{
                // delegate call to the exchange module
                (bool success, bytes memory data) = address(exchange).delegatecall(
                    abi.encodePacked(// This encodes the function to call and the parameters we are passing to the settlement function
                        exchange.swap.selector, 
                        abi.encode(
                            SwapParams({
                                sellToken : _swap.sellToken,
                                input     : thisInput,
                                buyToken  : _swap.buyToken,
                                minOutput : 1 // we are checking the combined output in the end
                            }),
                            _distribution.exchangeData[i]
                        )
                    )
                );
            
                require(success, "Exchange module reverted.");
            }
        }
        
        return balanceOf(_swap.buyToken);
    }
    
    // perform a distributed swap
    function swap(
        SwapParams memory _swap,
        DistributionParams memory _distribution
    ) public payable returns (uint _output){
        return swapAndSend(_swap, _distribution, msg.sender);
    }
    
    // perform a multi-path distributed swap
    function multiPathSwap(
        SwapParams memory _swap,
        Token[] calldata _path,
        DistributionParams[] memory _distribution
    ) public payable returns (uint _output){
        return multiPathSwapAndSend(_swap, _path, _distribution, msg.sender);
    }

    // allow ETH receivals
    receive() external payable {}
}

contract AtomicTokenProxy is AtomicUtils, AtomicTypes{
    AtomicBlue constant atomic = AtomicBlue(0xeb5DF44d56B0d4cCd63734A99881B2F3f002ECC2);

    // perform a distributed swap and transfer outcome to _receipient
    function swapAndSend(
        SwapParams calldata _swap,
        
        DistributionParams calldata _distribution,
        
        address payable _receipient
    ) public payable returns (uint _output){
        // deposit tokens to executor
        claimTokenFromSenderTo(_swap.sellToken, _swap.input, address(atomic));
        
        // execute swaps on behalf of sender
        _output = atomic.swapAndSend.value(msg.value)(_swap, _distribution, _receipient);
    }
    
    // perform a multi-path distributed swap and transfer outcome to _receipient
    function multiPathSwapAndSend(
        SwapParams calldata _swap,
        
        Token[] calldata _path,
        
        DistributionParams[] calldata _distribution,
        
        address payable _receipient
    ) public payable returns (uint _output){
        // deposit tokens to executor
        claimTokenFromSenderTo(_swap.sellToken, _swap.input, address(atomic));
        
        // execute swaps on behalf of sender
        _output = atomic.multiPathSwapAndSend.value(msg.value)(
            _swap,
            _path,
            _distribution,
            _receipient
        );
    }
    
    // perform a distributed swap
    function swap(
        SwapParams calldata _swap,
        DistributionParams calldata _distribution
    ) public payable returns (uint _output){
        return swapAndSend(_swap, _distribution, msg.sender);
    }
    
    // perform a distributed swap and burn optimal gastoken amount afterwards
    function swapWithGasTokens(
        SwapParams calldata _swap,
        DistributionParams calldata _distribution,
        IGasToken _gasToken,
        uint _gasQtyPerToken
    ) public payable returns (uint _output){
        uint startGas = gasleft();
        _output = swapAndSend(_swap, _distribution, msg.sender);
        _gasToken.freeFromUpTo(msg.sender, (startGas - gasleft() + 25000) / _gasQtyPerToken);
    }
    
    // perform a multi-path distributed swap
    function multiPathSwap(
        SwapParams calldata _swap,
        Token[] calldata _path,
        DistributionParams[] calldata _distribution
    ) public payable returns (uint _output){
        return multiPathSwapAndSend(_swap, _path, _distribution, msg.sender);
    }
    
    // perform a multi-path distributed swap and burn optimal gastoken amount afterwards
    function multiPathSwapWithGasTokens(
        SwapParams calldata _swap,
        Token[] calldata _path,
        DistributionParams[] calldata _distribution,
        IGasToken _gasToken,
        uint _gasQtyPerToken
    ) public payable returns (uint _output){
        uint startGas = gasleft();
        _output = multiPathSwapAndSend(_swap, _path, _distribution, msg.sender);
        _gasToken.freeFromUpTo(msg.sender, (startGas - gasleft() + 25000) / _gasQtyPerToken);
    }
    
    // perform a distributed swap, send outcome to _receipient and burn optimal gastoken amount afterwards
    function swapAndSendWithGasTokens(
        SwapParams calldata _swap,
        DistributionParams calldata _distribution,
        address payable _receipient,
        IGasToken _gasToken,
        uint _gasQtyPerToken
    ) public payable returns (uint _output){
        uint startGas = gasleft();
        _output = swapAndSend(_swap, _distribution, _receipient);
        _gasToken.freeFromUpTo(msg.sender, (startGas - gasleft() + 25000) / _gasQtyPerToken);
    }
    
    // perform a multi-path distributed swap, send outcome to _receipient and burn optimal gastoken amount afterwards
    function multiPathSwapAndSendWithGasTokens(
        SwapParams calldata _swap,
        Token[] calldata _path,
        DistributionParams[] calldata _distribution,
        address payable _receipient,
        IGasToken _gasToken,
        uint _gasQtyPerToken
    ) public payable returns (uint _output){
        uint startGas = gasleft();
        _output = multiPathSwapAndSend(_swap, _path, _distribution, _receipient);
        _gasToken.freeFromUpTo(msg.sender, (startGas - gasleft() + 25000) / _gasQtyPerToken);
    }
}


contract Token {
    function totalSupply() view public returns (uint256 supply) {}

    function balanceOf(address _owner) view public returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) public {}

    function transferFrom(address _from, address _to, uint256 _value)  public {}

    function approve(address _spender, uint256 _value) public {}

    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 public decimals;
    string public name;
}

contract IWETH is Token {
    function deposit() public payable {}

    function withdraw(uint256 amount) public {}
}

contract IGasToken {
    function freeUpTo(uint256 value) public returns (uint256) {
    }

    function free(uint256 value) public returns (uint256) {
    }
    
    function freeFrom(address from, uint256 value) public returns (uint256) {
    }

    function freeFromUpTo(address from, uint256 value) public returns (uint256) {
    }
}