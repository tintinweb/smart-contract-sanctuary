/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// Sources flattened with hardhat v2.7.1 https://hardhat.org

// File contracts/LevrSale.sol

pragma solidity 0.8.7;

interface IERC20Mintable 
{
    function mint(address, uint) external returns (bool);
}

contract SaleTest
{
    uint constant ONE_PERC = 10**16;
    uint constant ONE_HUNDRED_PERC = 10**18;
    uint constant STARTING_POINT = 1000 * 10**18;
    uint constant WAD = 10**18;

    uint public raised = STARTING_POINT; //used this to spare one storage slot and simplify later code                      
    uint public tokensIssued;                       
    uint public inclineWAD;                         

    IERC20Mintable public tokenOnSale;

    address public gulper;
    address public treasury;
    address public liquidity;
    address public foundryTreasury;

    constructor(
            uint _inclineWAD,
            IERC20Mintable _tokenOnSale, 
            address _gulper, 
            address _treasury, 
            address _liquidity, 
            address _foundryTreasury)
    {
        inclineWAD = _inclineWAD;
        tokenOnSale = _tokenOnSale;
        gulper = _gulper;
        treasury = _treasury;
        liquidity = _liquidity;
        foundryTreasury = _foundryTreasury;
    }

    event Bought
    (
        address _receiver,
        uint _amount
    );

    receive()
        payable
        external
    {
        buy(msg.sender);
    }

    function addToRaised(uint256 _addition)
        public
    {
        raised = raised + _addition;
    }

    function subractFromRaised(uint256 _sub)
        public
    {
        raised = raised - _sub;
    }

    function buy(address _receiver)
        public
        payable
    {
        uint tokensAssigned = calculateTokensReceived(msg.value);
        
        (bool success,) = gulper.call{value:msg.value}("");
        require(success, "gulper malfunction");

        tokensIssued = tokensIssued + tokensAssigned;   // Elmer Addition (Update tokensIssued)
        raised = raised + msg.value;                    // Elmer Addition (Update eth amount raised)

        mintTokens(_receiver, tokensAssigned);
        emit Bought(_receiver, tokensAssigned);
    }

    function mintTokens(address _receiver, uint _amount)
        private 
    {
        tokenOnSale.mint(_receiver, _amount/7*4);  // 4/7
        tokenOnSale.mint(treasury, _amount/7);          // 1/7
        tokenOnSale.mint(liquidity, _amount/7);         // 1/7
        tokenOnSale.mint(foundryTreasury, _amount/7);   // 1/7
    }

    function pureCalculateSupply(uint _inclineWAD, uint _raised)
        public
        pure
        returns(uint _tokens)
    {
        // (2*incline*raised)^0.5 
        _tokens = sqrt(uint(2) * _inclineWAD * _raised / WAD);
    }

    function pureCalculateTokensRecieved(uint _inclineWAD, uint _alreadyRaised, uint _supplied) 
        public
        pure
        returns (uint _tokensReturned)
    {
        _tokensReturned = pureCalculateSupply(_inclineWAD, _alreadyRaised + _supplied) - pureCalculateSupply(_inclineWAD, _alreadyRaised);
    }

    function calculateTokensReceived(uint _supplied)
        public
        view
        returns (uint _tokensReturned)
    {
        _tokensReturned = pureCalculateTokensRecieved(inclineWAD, raised, _supplied);       
    }

    function pureCalculatePricePerToken(uint _inclineWAD, uint _alreadyRaised, uint _supplied)              
        public
        pure                                                                        
        returns(uint _price)
    {
        // _price = pureCalculateTokensRecieved(_inclineWAD, _alreadyRaised, _supplied) * WAD / _supplied; // Was previously
        _price = _supplied * WAD / pureCalculateTokensRecieved(_inclineWAD, _alreadyRaised, _supplied); // Elmer change
    }

    function calculatePricePerToken(uint _supplied)
        public
        view
        returns(uint _price)
    {
        _price = pureCalculatePricePerToken(inclineWAD, raised, _supplied); // 0.0000750709074
                                                                            // 0.000075070907398619
    }

    // babylonian method
    function sqrt(uint x) 
        public 
        pure
        returns (uint y) 
    {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x/z + z) / 2;
            (x/z + z)/2;
        }
    }
}