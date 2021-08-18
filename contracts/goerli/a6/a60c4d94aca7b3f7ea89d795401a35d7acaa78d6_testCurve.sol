/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity >=0.5.0;


// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testCurve {


    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function test(uint256 initial_supply) public returns (uint256) {
    
        return initial_supply;
        // require(_initial_supply >= 1, "SafeMath: addition overflow");
        // emit AuctionEnded(highestBidder, highestBid);
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
 
    function requiredCollateral(uint256 _initialSupply)
        public
        view
        returns (uint256)
    {
        return _initializeCurve(_initialSupply);
    }   
    
    function _initializeCurve(uint256 _initial_supply)
        internal
        view
        returns (uint256 price)
    {
        price = _mint(_initial_supply, 0);
        return price;
    }
    
    
    function _primitiveFunction(uint256 s) internal view returns (uint256) {
        return add(s,_helper(s));
    }
    
    function _helper(uint256 x) internal view returns (uint256) {
        uint256 _BZZ_SCALE = 1e16;
        uint256 _N = 5;
        uint256 _MARKET_OPENING_SUPPLY = 62500000 * _BZZ_SCALE;
        for (uint256 index = 1; index <= _N; index++) {
            // x = (x.mul(x)).div(_MARKET_OPENING_SUPPLY);
            x = mul(x,x);
            x = div(x,_MARKET_OPENING_SUPPLY);
        }
        return x;
    }

    
    function _mint(uint256 _amount, uint256 _currentSupply)
        internal
        view
        returns (uint256)
    {
        // uint256 deltaR = _primitiveFunction(_currentSupply.add(_amount)).sub(
            //  _primitiveFunction(_currentSupply));
        uint256 tmp = sub(add(_currentSupply,_amount),_primitiveFunction(_currentSupply));
        uint256 deltaR = _primitiveFunction(tmp);
        return deltaR;
    }

    function buyPrice(uint256 _amount,uint256 _totalSupply)
        public
        view
        returns (uint256 collateralRequired)
    {
        collateralRequired = _mint(_amount, _totalSupply);
 
        return collateralRequired;
    }
    
    function sellReward(uint256 _amount,uint256 _totalSupply)
        public
        view
        returns (uint256 collateralReward)
    {
        collateralReward = _withdraw(_amount, _totalSupply);
        return collateralReward;
    }

    function _withdraw(uint256 _amount, uint256 _currentSupply)
        internal
        view
        returns (uint256 realized_price)
    {
        assert(_currentSupply - _amount > 0);
        uint256 deltaR = sub(_primitiveFunction(_currentSupply),_primitiveFunction(sub(_currentSupply,_amount)));
        realized_price = div(deltaR,_amount);
        // uint256 deltaR = _primitiveFunction(_currentSupply).sub(
        //     _primitiveFunction(_currentSupply.sub(_amount)));
        // uint256 realized_price = deltaR.div(_amount);
        // return (deltaR, realized_price);
        return realized_price;
    }
    
}