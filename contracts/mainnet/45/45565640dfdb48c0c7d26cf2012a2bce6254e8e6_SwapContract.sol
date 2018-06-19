pragma solidity ^0.4.23;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren&#39;t abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract BancorConverter {

    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256);

    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn)
        public
        payable
        returns (uint256);

    function quickConvertPrioritized(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, uint256 _block, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s)
        public
        payable
        returns (uint256);

    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);

}

contract SwapContract {


	BancorConverter Bancor = BancorConverter(0xc6725aE749677f21E4d8f85F41cFB6DE49b9Db29);
	IERC20Token ETHToken = IERC20Token(0xc0829421C1d260BD3cB3E0F06cfE2D52db2cE315);
	IERC20Token BNTToken = IERC20Token(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);

    IERC20Token[] path;
	

	constructor() public {
	   }
	
	function test() public payable {
	   path = [ETHToken,BNTToken,BNTToken];
	   Bancor.quickConvert.value(address(this).balance)(path,address(this).balance,1);
	}

    function testWithNewPath(IERC20Token[] _path) public payable {
	   Bancor.quickConvert.value(address(this).balance)(_path,address(this).balance,1);
    }
	
	/**
    * @notice Function to claim ANY token stuck on contract accidentally
    * In case of claim of stuck tokens please contact contract owners
    */
    function claimTokens(IERC20Token _address, address _to) public {
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(this); //Check remainder tokens
        _address.transfer(_to,remainder); //Transfer tokens to creator
    }
	
}