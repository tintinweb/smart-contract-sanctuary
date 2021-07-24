// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;

import "./utils.sol";

contract SWP {
    
    using SafeMath for uint256;
    
    address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // TESTNet
    //address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    
    address constant PK_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // TESTNet
    //address constant PK_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    
    string  constant  name = "Swapper";
    string  constant  symbol = "SWP";
    uint256 constant initialShares = 1000000000000000000; // 10^18
    uint256 constant MAXINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint8   constant decimals = 18;
    uint256 constant SLIPPAGE = 90;

    uint256 public  totalSupply = 0; // 10^18

    
    address private owner;
    address[] public assets;
    mapping(address => uint) public holdings; // position in `assets`
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    constructor() {
        balanceOf[msg.sender] = 0;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    // Standard transfer functions
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to].add(_value);
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    
    // Invest and disinvest
    
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED DC');
    }
    
    function invest(uint256 _bnb) public returns (bool success) {
        // Need to approve manually first

        uint256 share = 0;
    
        // Create shares
        if (AUM()>0) {
            share = _bnb.mul(totalSupply).div(AUM());
        } else {
            share = initialShares;
        }
        
        // Transfer WBNB
        safeTransferFrom(WBNB, msg.sender, address(this), _bnb);

        // Distribute shares
        totalSupply = totalSupply.add(share);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(share);

        return true;
    }
    
    function disinvest(uint256 _swp) public returns (bool success) {
        
        require(balanceOf[msg.sender] >= _swp);

        // Calculate WBNB amount
        uint256 _bnb = _swp.mul(AUM()).div(totalSupply);

        // TO-DO: Better handle the case in which not enough WBNB are available
        // Currently, it just sells the entire holdings of each token, 
        // starting from the one purchased most recently, 
        // until the CASH amount is large enough to over the outflow
        
        while (_bnb > CASH()) {
            address[] memory path = new address[](2);
            path[1] = WBNB;
            path[0] = assets[assets.length - 1]; // Sell the last token from `assets` 
            sellTokenAll(path);                  // This removes the last token from `assets`
            _bnb = _swp.mul(AUM()).div(totalSupply);
        }

        // Transfer WBNB
        safeTransferFrom(WBNB, address(this), msg.sender, _bnb);

        // Burn shares
        balanceOf[msg.sender] -= _swp;
        totalSupply -= _swp;

        return true;
   
    }
    
    
    // Owner's functions to trade 
    
    function approvePancake(address _token) public onlyOwner returns (bool _success) { 
        
        if (ERC20(_token).allowance(address(this), PK_ROUTER) < MAXINT.div(10)) {
            return ERC20(_token).approve(PK_ROUTER, MAXINT);
        } else {
            return true;
        }
    }

    function addAsset(address _token) private {
        assets.push(_token);
        holdings[_token] = assets.length-1;
    }

    function removeAsset(address _token) private {
        uint index = holdings[_token];
        assets[index] = assets[assets.length - 1]; // Move the last element into the place to delete
        assets.pop(); // Remove the last element
    }
    
    function buyToken(address[] calldata path, uint256 _bnb) public onlyOwner returns (bool _success) {
        
        approvePancake(WBNB);
        uint256 owned = ERC20(path[1]).balanceOf(address(this));
        uint256 amount = PK(PK_ROUTER).getAmountsOut(_bnb, path)[1];
        amount = amount.mul(100-SLIPPAGE).div(100); // amountOutMin
        PK(PK_ROUTER).swapExactTokensForTokens( _bnb, amount, path, address(this), block.timestamp + 60 );
        if (owned==0) { addAsset(path[1]); } // Record new position
        return true;
        
    }
    
    function sellToken(address[] memory path, uint256 _amount) public onlyOwner returns (bool _success) {
        // Need to approve before this
        uint256 owned = ERC20(path[0]).balanceOf(address(this));
        uint256 amount = PK(PK_ROUTER).getAmountsOut(_amount, path)[1];
        amount = amount.mul(100-SLIPPAGE).div(100); // amountOutMin
        PK(PK_ROUTER).swapExactTokensForTokens( _amount, amount, path, address(this), block.timestamp + 60 );
        if ( owned <= _amount ) { removeAsset(path[0]); } // Delete the old position
        return true;
    
    }

    function sellTokenAll(address[] memory path) public onlyOwner returns (bool _success) {
        approvePancake(path[0]);
        uint256 balance = ERC20(path[0]).balanceOf(address(this));
        uint256 amount = PK(PK_ROUTER).getAmountsOut(balance, path)[1];
        amount = amount.mul(100-SLIPPAGE).div(100); // amountOutMin
        PK(PK_ROUTER).swapExactTokensForTokens( balance, amount, path, address(this), block.timestamp + 60 );
        removeAsset(path[0]); // Delete the old position
        return true;
    }
    
    
    
    // Views
    
    function M2M() public view returns (uint256 _m2m) {
        uint256 m2m = 0;
        uint256 amount;
        address[] memory path    = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        path[1] = WBNB;
        
        for (uint i=0; i<assets.length; i++) {
            path[0] = assets[i];
            amount  = ERC20(assets[i]).balanceOf(address(this));
            amounts = PK(PK_ROUTER).getAmountsOut(amount, path);
            m2m = m2m.add(amounts[1]);       
        }
        return m2m;
    }
    
    function AUM() public view returns (uint256 amount) {
        return CASH().add(M2M());
    }
    
    function CASH() public view returns (uint256 amount) {
        return ERC20(WBNB).balanceOf(address(this));
    }
    
    function SharePrice() public view returns (uint256 _price) {
        return AUM().mul(initialShares).div(totalSupply);
    }
    
    function Weight(address _token) public view returns (uint256 _weight) {
        if (_token==WBNB) {
            return CASH().mul(initialShares).div(AUM());    
        } else {
            address[] memory path = new address[](2);
            path[0] = _token;
            path[1] = WBNB;
            uint256 amount  = ERC20(_token).balanceOf(address(this));
            amount = PK(PK_ROUTER).getAmountsOut(amount, path)[1];
            return amount.mul(initialShares).div(AUM());    
        }
        
    }
    
}




// 0x095ea7b3 approve(address,uint256)
// 0xd06ca61f getAmountsOut(uint256,address[])    
// 0x38ed1739 swapExactTokensForTokens
// 0xf7639be3 swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,address[])