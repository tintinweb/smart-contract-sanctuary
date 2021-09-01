/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

abstract contract ERC20 {
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);
    function totalSupply() external view virtual returns (uint256);
    function balanceOf(address _owner) external view virtual returns (uint256);
    function allowance(address _owner, address _spender) external view virtual returns (uint256);
    function transfer(address _to, uint256 _value) external virtual returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external virtual returns (bool);

    function approve(address _spender, uint256 _value) external virtual returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

contract Grapenopoly
{
    struct PropertyModel {
        uint256 id;
        string name;
        string description;
        string imageURI;
        uint256 price;
        uint state;
        uint zone;
        uint256[] rent;
        uint256[] housePrice;
        uint houseAmount;
        //uint256 mortgage;
        uint256 saleprice;
        address owner;
    }

    struct DiceResult {
        uint[3] faces;
        uint steps;
        uint256 collectedPrize;
        uint256 paidTaxes;
        uint256 paidRent;
    }

    // NFT Properties
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02; //https://eips.ethereum.org/EIPS/eip-721
    uint256 public id;
    mapping(bytes4 => bool) public supportsInterface; // ERC-165
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private nftOwners;
    mapping(uint256 => address) private approvedOperator;
    mapping(address => mapping(address => bool)) private approvedForAll;

    // NFT Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Game Properties
    address public networkcoinaddress;
    address public owner;
    address public feeandtaxreceiver;
    uint private diceFaces;
    uint private diceNonce;
    uint private prizeNonce;
    uint256 private MAX_NONCE;
    string public nftURI;
    uint public maxHouseAmount;
    uint public prizeWalkAmount;
    uint public taxesWalkAmount;
    uint public prizeLandMaxPay;
    uint public taxesLandMaxPay;
    uint public minUSDBalanceToWalk;
    address public tokenToPayPrize;
    address public tokenToCollectTax;
    address public tokenToUseOnSellPropertyToBank;
    address public usdToken;
    address public chainWrapToken;
    address public swapFactory;

    mapping(uint256 => string) private nftName;
    mapping(uint256 => string) private nftDescription;
    mapping(uint256 => string) private nftImageURI;
    mapping(uint256 => uint256) private nftPrice;
    mapping(uint256 => uint) private nftState;
    mapping(uint256 => uint) private nftZone;
    mapping(uint256 => mapping(uint => uint256)) private nftRent;
    mapping(uint256 => mapping(uint => uint256)) private nftHousePrice;
    //mapping(uint256 => uint) private nftMortgage;
    mapping(address => uint256) public playerPosition;
    mapping(uint256 => uint) private nftHouseAmount; //0 = empty | maxHouseAmount + 1 = hotel
    
    mapping(address => uint) private playerAccumulatedStepsFromLastTax;
    mapping(address => uint) private playerAccumulatedStepsFromLastPrize;

    mapping(uint256 => uint) private propertySalePrice; //Property For Sale defined by NFT Owner | 0 USD = Not for sale

    //Min Deposit for each Token
    mapping(address => uint256) public minDeposit;

    //Min Withdraw for each Token
    mapping(address => uint256) public minWithdraw;

    //User lists (1st mapping user, 2nd mapping token)
    mapping(address => mapping(address => uint256)) private vaultBalances;



    // *********************************************************
    // ********************* POWER UP VARS *********************
    // *********************************************************
    uint256 private ONE = 1000000000000000000;

    struct PowerUpRecord 
    {
        uint multiply;
        uint visits;
    }

    //Power-up token record by Token Address
    mapping(address => PowerUpRecord) private powerUpRecordList;

    //Power-up id to Powerup Address
    mapping(uint => address) private powerUpAddresses;


    //Deposited NFT-Token/Power-up address to get added powerup 0 (false) or 1 (true)
    mapping(uint => mapping(address => uint)) private depositedPowerup;
    mapping(uint => mapping(address => uint)) private depositedPowerupVisits;
    
    uint private powerUpIdSeed;
    //**********************************************************



    //Game Events
    event OnDeposit(address from, address token, uint256 total);
    event OnWithdraw(address to, address token, uint256 total);
    event OnRollDices(DiceResult result);
    event OnHouseOrHotelBuy(uint256 tokenId, address selectedTokenToPayBuild, uint buildIndex);
    event OnHouseOrHotelSell(uint256 tokenId, address selectedTokenToReceive, uint buildIndex);
    event OnBuyPropertyFromBank(uint256 _tokenId, address selectedTokenToPay);
    event OnBuyPropertyForSale(uint256 _tokenId, address selectedTokenToPay, uint256 salePrice);


    constructor()
    {
        //NFT Startup Attributes
        supportsInterface[0x80ac58cd] = true; // ERC-721 
        supportsInterface[0x5b5e139f] = true; // METADATA
        supportsInterface[0x01ffc9a7] = true; // EIP-165

        //Game Startup Attributes
        owner = msg.sender;
        networkcoinaddress = address(0x1110000000000000000100000000000000000111);
        feeandtaxreceiver = msg.sender;
        diceFaces = 6;
        diceNonce = 29689;
        prizeNonce = 3711;
        MAX_NONCE = 237512;
        maxHouseAmount = 9;
        nftURI = "https://grapestaking.lidia.in/nft-info/";
        prizeWalkAmount = 30;
        taxesWalkAmount = 20;
        tokenToPayPrize = networkcoinaddress;
        tokenToCollectTax = networkcoinaddress;
        prizeLandMaxPay = 10000000000000000; //0.01
        taxesLandMaxPay = 10000000000000000; //0.01
        minUSDBalanceToWalk = 2000000000000000000; //2 USD
        usdToken = block.chainid == 56 ?        address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56) : 
                    (block.chainid == 1 ?       address(0xdAC17F958D2ee523a2206206994597C13D831ec7) : 
                    (block.chainid == 43114 ?   address(0xde3A24028580884448a5397872046a019649b084) : 
                    (block.chainid == 97 ?      address(0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee) : 
                                                address(0) ) ) );

        chainWrapToken = block.chainid == 56 ?  address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c) : 
                    (block.chainid == 1 ?       address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) : 
                    (block.chainid == 43114 ?   address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7) : 
                    (block.chainid == 97 ?      address(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd) : 
                                                address(0) ) ) );

        swapFactory = block.chainid == 56 ?     address(0xBCfCcbde45cE874adCB698cC183deBcF17952812) : 
                    (block.chainid == 1 ?       address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f) : 
                    (block.chainid == 43114 ?   address(0xefa94DE7a4656D787667C749f7E1223D71E9FD88) : 
                    (block.chainid == 97 ?      address(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc) : 
                                                address(0) ) ) );

        //GRAPE
        tokenToUseOnSellPropertyToBank = block.chainid == 56 ?       address(0xb699390735ed74e2d89075b300761daE34b4b36B) : 
                                        (block.chainid == 1 ?       address(0) : 
                                        (block.chainid == 43114 ?   address(0x17757dcE604899699b79462a63dAd925B82FE221) : 
                                        (block.chainid == 97 ?      address(0x76B9660C78Cf4fB6bC3E489cEc37cb538ab54daE) : 
                                                                    address(0) ) ) );
    }

    // **********************************************
    // *************** GAME FUNCTIONS ***************
    // **********************************************
    function depositToken(address token, uint256 amountInWei) external 
    {
        require(ERC20(token).allowance(msg.sender, address(this)) >= amountInWei, "AL"); //VAULT: Check the token allowance. Use approve function.
        require(amountInWei >= minDeposit[token], "DL"); //VAULT: Deposit value is too low.

        ERC20(token).transferFrom(msg.sender, address(this), amountInWei);
        uint256 currentTotal = vaultBalances[msg.sender][token];

        //Increase/register deposit balance
        vaultBalances[msg.sender][token] = SafeMath.safeAdd(currentTotal, amountInWei);
        emit OnDeposit(msg.sender, token, amountInWei);
    }

    function depositNetworkCoin() external payable 
    {
        require(msg.value > 0, "DL"); //VAULT: Deposit value is too low.
        require(msg.value >= minDeposit[networkcoinaddress], "DL"); //VAULT: Deposit value is too low.

        uint256 currentTotal = vaultBalances[msg.sender][networkcoinaddress];

        //Increase/register deposit balance
        vaultBalances[msg.sender][networkcoinaddress] = SafeMath.safeAdd(currentTotal, msg.value);
        emit OnDeposit(msg.sender, networkcoinaddress, msg.value);
    }

    function withdraw(address token, uint256 amountInWei) external
    {
        systemWithdraw(msg.sender, token, amountInWei, 0);
    }

    function forcePlayerWithdraw(address player, address token, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        systemWithdraw(player, token, amountInWei, 0);
    }

    function forceSystemWithdraw(address toAddress, address token, uint256 amountInWei) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        systemWithdraw(toAddress, token, amountInWei, 1);
    }

    function systemWithdraw(address player, address token, uint256 amountInWei, uint dontChangeBalances) internal 
    {
        require(amountInWei >= minWithdraw[token], "WL"); //VAULT: Withdraw value is too low.

        uint sourceBalance;
        if(address(token) != networkcoinaddress)
        {
            //Balance in Token
            sourceBalance = ERC20(token).balanceOf(address(this));
        }
        else
        {
            //Balance in Network Coin
            sourceBalance = address(this).balance;
        }

        require(sourceBalance >= amountInWei, "LW"); //VAULT: Too low reserve to withdraw the requested amount

        //Withdraw of deposit value
        if(token != networkcoinaddress)
        {
            //Withdraw token
            ERC20(token).transfer(player, amountInWei);
        }
        else
        {
            //Withdraw Network Coin
            payable(player).transfer(amountInWei);
        }

        if(dontChangeBalances == 0)
        {
            uint256 currentTotal = vaultBalances[player][token];
            vaultBalances[player][token] = SafeMath.safeSub(currentTotal, amountInWei);
        }

        emit OnWithdraw(player, token, amountInWei);
    }

    function buyPropertyFromBank(uint256 _tokenId, address selectedTokenToPay) external
    {
        require(nftOwners[ _tokenId ] == feeandtaxreceiver, 'bk'); //Must be a bank property
        uint256 nftPriceValue = nftPrice[_tokenId];
        uint256 vaultBalanceValue = vaultBalances[msg.sender][selectedTokenToPay];
        require(vaultBalanceValue >= SafeMath.safeMulFloat(nftPriceValue, getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()), "NB"); //No balance for purchase
        require(playerPosition[msg.sender] == _tokenId, 'ip'); //Invalid player position

        //Pay to Bank - Withdraw from contract to Fee and Tax Receiver Address
        if(address(selectedTokenToPay) != networkcoinaddress)
        {
            //Send token amount to Fee and Tax Receiver Address
            ERC20(selectedTokenToPay).transfer(feeandtaxreceiver, SafeMath.safeMulFloat(nftPriceValue, getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()));
        }
        else
        {
            //Send Network Coin to Fee and Tax Receiver Address
            payable(feeandtaxreceiver).transfer(SafeMath.safeMulFloat(nftPriceValue, getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()));
        }

        //Subtract amount of user balance
        vaultBalances[msg.sender][selectedTokenToPay] = SafeMath.safeSub(vaultBalanceValue, SafeMath.safeMulFloat(nftPriceValue, getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()) );

        //Transfer Property Ownership
        _transfer(feeandtaxreceiver, msg.sender, _tokenId);

        emit OnBuyPropertyFromBank(_tokenId, selectedTokenToPay);
    }

    function buyPropertyForSale(uint256 _tokenId, address selectedTokenToPay) external
    {
        uint onSalePrice = propertySalePrice[ _tokenId ];
        require(onSalePrice > 0, 'N'); //Not for sale
        require(nftOwners[ _tokenId ] != feeandtaxreceiver, 'bk'); //Bank is the property owner
        require(nftOwners[ _tokenId ] != msg.sender, 'O'); //Owned: You are the owner
        uint256 vaultBalanceValue = vaultBalances[msg.sender][selectedTokenToPay];
        
        //It uses safesub, does not need to check
        //require(vaultBalanceValue >= SafeMath.safeMulFloat(onSalePrice, getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()), "NB"); //No balance for purchase

        require(playerPosition[msg.sender] == _tokenId, 'ip'); //Invalid player position

        //*** Pay to Owner ***
        //Subtract amount of user balance
        vaultBalances[msg.sender][selectedTokenToPay] = SafeMath.safeSub(vaultBalanceValue, SafeMath.safeMulFloat(onSalePrice, getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()) );

        //Add amount to NFT owner
        vaultBalances[ nftOwners[ _tokenId ] ][selectedTokenToPay] = SafeMath.safeAdd(vaultBalances[ nftOwners[ _tokenId ] ][selectedTokenToPay], SafeMath.safeMulFloat(onSalePrice, getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()));
        
        //Transfer Property Ownership (transfer will Remove for SALE board: propertySalePrice[ _tokenId ] = 0;)
        _transfer(nftOwners[ _tokenId ], msg.sender, _tokenId);

        emit OnBuyPropertyForSale(_tokenId, selectedTokenToPay, onSalePrice);
    }

    function putUpPropertyForSale(uint256 _tokenId, uint256 salePrice) external
    {
        require(nftOwners[ _tokenId ] == msg.sender, 'own'); //You don't own this property
        propertySalePrice[ _tokenId ] = salePrice;
    }

    function buyHouseOrHotelForProperty(uint256 _tokenId, address selectedTokenToPayBuild) external
    {
        //Price: nftHousePrice[_tokenId][buildIndex]
        //Next Build Index: safeAdd(nftHouseAmount[ _tokenId ], 1);

        uint buildAmount = nftHouseAmount[ _tokenId ];
        require(buildAmount < SafeMath.safeAdd(maxHouseAmount, 1), 'mx'); //Maximum builds reached
        require(nftOwners[ _tokenId ] == msg.sender, 'own'); //You don't own this property

        uint256 vaultBalanceValue = vaultBalances[msg.sender][selectedTokenToPayBuild];
        uint256 newBuildPrice = nftHousePrice[_tokenId][ SafeMath.safeAdd(nftHouseAmount[ _tokenId ], 1) ];

        //It uses safesub, does not need to check
        //require(SafeMath.safeMulFloat(vaultBalanceValue, getQuote(usdToken, selectedTokenToPayBuild), ERC20(usdToken).decimals()) >= newBuildPrice, "NB"); //No balance to build

        //Pay for the house or hotel
        //vaultBalances[msg.sender][selectedTokenToPayBuild] = SafeMath.safeSub(vaultBalanceValue, newBuildPrice);
        //uint256 newBuildPriceInToken = SafeMath.safeMulFloat(getQuote(selectedTokenToPayBuild, usdToken), newBuildPrice, ERC20(selectedTokenToPayBuild).decimals());
        //vaultBalances[msg.sender][selectedTokenToPayBuild] = SafeMath.safeSub(vaultBalanceValue, newBuildPriceInToken);
        vaultBalances[msg.sender][selectedTokenToPayBuild] = SafeMath.safeSub(vaultBalanceValue, SafeMath.safeMulFloat(getQuote(usdToken, selectedTokenToPayBuild), newBuildPrice, ERC20(usdToken).decimals()));

        //Update build index
        nftHouseAmount[ _tokenId ] = SafeMath.safeAdd(buildAmount, 1);

        emit OnHouseOrHotelBuy(_tokenId, selectedTokenToPayBuild, nftHouseAmount[ _tokenId ]);
    }

    function sellHouseOrHotelProperty(uint256 _tokenId) external
    {
        require(nftOwners[ _tokenId ] == msg.sender, 'own'); //You don't own this property
        uint buildAmount = nftHouseAmount[ _tokenId ];
        require(buildAmount > 0, 'nh'); //No house to sell

        //Receive for house or hotel selling
        //vaultBalances[msg.sender][tokenToUseOnSellPropertyToBank] = SafeMath.safeAdd( vaultBalances[msg.sender][tokenToUseOnSellPropertyToBank], nftHousePrice[_tokenId][ buildAmount ]);
        //uint256 sellBuildPriceInToken = SafeMath.safeMulFloat(getQuote(tokenToUseOnSellPropertyToBank, usdToken), nftHousePrice[_tokenId][ buildAmount ], ERC20(tokenToUseOnSellPropertyToBank).decimals());
        //vaultBalances[msg.sender][tokenToUseOnSellPropertyToBank] = SafeMath.safeAdd( vaultBalances[msg.sender][tokenToUseOnSellPropertyToBank], sellBuildPriceInToken);
        vaultBalances[msg.sender][tokenToUseOnSellPropertyToBank] = SafeMath.safeAdd( vaultBalances[msg.sender][tokenToUseOnSellPropertyToBank], SafeMath.safeMulFloat(getQuote(usdToken, tokenToUseOnSellPropertyToBank), nftHousePrice[_tokenId][ buildAmount ], ERC20(usdToken).decimals()));

        //Update build index
        nftHouseAmount[ _tokenId ] = SafeMath.safeSub(buildAmount, 1);

        emit OnHouseOrHotelSell(_tokenId, tokenToUseOnSellPropertyToBank, SafeMath.safeAdd(nftHouseAmount[ _tokenId ], 1) );
    }

    function rollDices(address selectedTokenToPayRent) external
    {
        require(SafeMath.safeMulFloat(vaultBalances[msg.sender][selectedTokenToPayRent], getQuote(usdToken, selectedTokenToPayRent), ERC20(usdToken).decimals()) >= minUSDBalanceToWalk, "NB"); //No balances for moving
        require(id > SafeMath.safeMul(3, diceFaces), "LP" ); //Low properties for dices rolling
        require(vaultBalances[msg.sender][tokenToCollectTax] >= taxesLandMaxPay, "LTB"); //Low tax balance: You must be prepared to pay maximum tax before walk

        DiceResult memory result;
        result.faces = [Hlp.getFace(diceNonce, diceFaces), Hlp.getFace( SafeMath.safeAdd(diceNonce, 1), diceFaces), Hlp.getFace(SafeMath.safeAdd(diceNonce, 2), diceFaces)];
        diceNonce = diceNonce >= MAX_NONCE ? 0 : SafeMath.safeAdd(diceNonce, 3);

        result.steps = SafeMath.safeAdd(result.steps, SafeMath.safeAdd(SafeMath.safeAdd(result.faces[0], result.faces[1]), result.faces[2]));

        uint[] memory propList = Hlp.sortZone(id, nftZone);
        
        uint currentPlayerPositionIndex;
        uint newPlayerPositionIndex;
        if(playerPosition[msg.sender] > 0)
        {
            for(uint ix = 0; ix < propList.length; ix++)
            {
                if(propList[ix] == playerPosition[msg.sender])
                {
                    currentPlayerPositionIndex = ix;
                    break;
                }
            }
        }

        //Check if went around the board
        if(SafeMath.safeAdd(currentPlayerPositionIndex, result.steps) > propList.length - 1)
        {
            newPlayerPositionIndex = SafeMath.safeSub(SafeMath.safeAdd(currentPlayerPositionIndex, result.steps), propList.length);
        }
        else
        {
            newPlayerPositionIndex = SafeMath.safeAdd(currentPlayerPositionIndex, result.steps);
        }

        playerPosition[msg.sender] = propList[newPlayerPositionIndex];

        //Update accumulated steps
        playerAccumulatedStepsFromLastTax[msg.sender] = SafeMath.safeAdd(playerAccumulatedStepsFromLastTax[msg.sender], result.steps);
        playerAccumulatedStepsFromLastPrize[msg.sender] = SafeMath.safeAdd(playerAccumulatedStepsFromLastPrize[msg.sender], result.steps);

        if(prizeWalkAmount > 0 && playerAccumulatedStepsFromLastPrize[msg.sender] >= prizeWalkAmount)
        {
            //Reset accumalated steps
            playerAccumulatedStepsFromLastPrize[msg.sender] = SafeMath.safeSub(playerAccumulatedStepsFromLastPrize[msg.sender], taxesWalkAmount);

            //Collect prize
            uint256 prizeValue = Hlp.clockN(SafeMath.safeMul(prizeNonce, 7), prizeLandMaxPay);

            if(SafeMath.safeAdd(prizeNonce, 1) >= MAX_NONCE)
            {
                prizeNonce = 0;
            }
            prizeNonce++;

            if(prizeValue > 0)
            {
                vaultBalances[msg.sender][tokenToPayPrize] = SafeMath.safeAdd(vaultBalances[msg.sender][tokenToPayPrize], prizeValue);
                result.collectedPrize = prizeValue;
            }
        }

        if(taxesWalkAmount > 0 && playerAccumulatedStepsFromLastTax[msg.sender] >= taxesWalkAmount)
        {
            //Reset accumalated steps
            playerAccumulatedStepsFromLastTax[msg.sender] = SafeMath.safeSub(playerAccumulatedStepsFromLastTax[msg.sender], taxesWalkAmount);

            //Pay tax
            uint256 taxValue = Hlp.clockN(SafeMath.safeMul(prizeNonce, 5), taxesLandMaxPay);

            if(SafeMath.safeAdd(prizeNonce, 1) >= MAX_NONCE)
            {
                prizeNonce = 0;
            }
            prizeNonce++;

            if(taxValue > 0)
            {
                if(vaultBalances[msg.sender][tokenToCollectTax] > taxValue)
                {
                    result.paidTaxes = taxValue;
                    vaultBalances[msg.sender][tokenToCollectTax] = SafeMath.safeSub(vaultBalances[msg.sender][tokenToCollectTax], taxValue);
                }
                else
                {
                    result.paidTaxes = vaultBalances[msg.sender][tokenToCollectTax];
                    vaultBalances[msg.sender][tokenToCollectTax] = 0;
                }

                if(address(selectedTokenToPayRent) != networkcoinaddress)
                {
                    //Pay tax in token
                    ERC20(selectedTokenToPayRent).transfer(feeandtaxreceiver, taxValue);
                }
                else
                {
                    //Pay tax in network coin
                    payable(feeandtaxreceiver).transfer(taxValue);
                }
            }
        }

        //Pay rent if is not your property and if is not bank property
        if(nftOwners[ playerPosition[msg.sender] ] != msg.sender && nftOwners[ playerPosition[msg.sender] ] != feeandtaxreceiver)
        {
            //Convert rent from USD to token to pay rent
            uint houseAmount = nftHouseAmount[ playerPosition[msg.sender] ];
            
            if(houseAmount > maxHouseAmount + 1)
            {
                houseAmount = maxHouseAmount + 1;
            }

            if(nftRent[ playerPosition[msg.sender] ][ houseAmount ] > 0)
            {
                //uint256 rentValueInToken = SafeMath.safeMulFloat(nftRent[ playerPosition[msg.sender] ][ houseAmount ], getQuote(usdToken, selectedTokenToPayRent), ERC20(usdToken).decimals());

                // ******* POWER-UP CHECK *******
                //uint powerupMultiplier = setPowerUPOnNFTVisits(playerPosition[msg.sender]);
                //*******************************
                //uint256 rentValueInToken = SafeMath.safeMul(powerupMultiplier, SafeMath.safeMulFloat(nftRent[ playerPosition[msg.sender] ][ houseAmount ], getQuote(usdToken, selectedTokenToPayRent), ERC20(usdToken).decimals()));

                uint256 rentValueInToken = SafeMath.safeMul(setPowerUPOnNFTVisits(playerPosition[msg.sender]), SafeMath.safeMulFloat(nftRent[ playerPosition[msg.sender] ][ houseAmount ], getQuote(usdToken, selectedTokenToPayRent), ERC20(usdToken).decimals()));

                if(rentValueInToken > 0)
                {
                    if(vaultBalances[msg.sender][selectedTokenToPayRent] >= rentValueInToken)
                    {
                        //Pay rent to nftOwner
                        vaultBalances[msg.sender][selectedTokenToPayRent] = SafeMath.safeSub(vaultBalances[msg.sender][selectedTokenToPayRent], rentValueInToken);
                        vaultBalances[ nftOwners[ playerPosition[msg.sender] ] ][selectedTokenToPayRent] = SafeMath.safeAdd(vaultBalances[ nftOwners[ playerPosition[msg.sender] ] ][selectedTokenToPayRent], rentValueInToken);
                        result.paidRent = rentValueInToken;
                    }
                    else
                    {
                        //Player bankrupt: Not enough to pay rent, player his amount and is stopped
                        uint256 willingToPay = SafeMath.safeSub(rentValueInToken, vaultBalances[msg.sender][selectedTokenToPayRent]);
                        
                        //Pay rent to nftOwner
                        vaultBalances[msg.sender][selectedTokenToPayRent] = 0;
                        vaultBalances[ nftOwners[ playerPosition[msg.sender] ] ][selectedTokenToPayRent] = willingToPay;
                        result.paidRent = willingToPay;

                        //Reset player position to zero
                        playerPosition[msg.sender] = 0;

                        //Reset accumulated walk steps
                        playerAccumulatedStepsFromLastTax[msg.sender] = 0;
                        playerAccumulatedStepsFromLastPrize[msg.sender] = 0;
                    }
                }
            }
        }

        emit OnRollDices(result);
    }

    //Get Attribute Values
    function getPlayerBalance(address player, address token) external view returns (uint256 value)
    {
        return vaultBalances[player][token];
    }

    function getPropertyList() external view returns (PropertyModel[] memory)
    {
        PropertyModel[] memory result = new PropertyModel[]( id );

        if(id > 0)
        {
            for(uint idRead = 1; idRead <= id; idRead++)
            {
                uint256[] memory rent = new uint256[](maxHouseAmount + 2);
                uint256[] memory housePrice = new uint256[](maxHouseAmount + 2);

                for(uint ixRent = 0; ixRent <= maxHouseAmount + 1; ixRent++)
                {
                    rent[ixRent] = nftRent[idRead][ixRent]; //First is no house and last is hotel
                    housePrice[ixRent] = nftHousePrice[idRead][ixRent]; //First is no house (zero) and last is hotel
                }

                //Insert property
                result[idRead - 1] = PropertyModel({
                    id: idRead,
                    name: nftName[idRead],
                    description: nftDescription[idRead],
                    imageURI: getNFTImage(idRead),
                    price: nftPrice[idRead],
                    state: nftState[idRead],
                    zone: nftZone[idRead],
                    rent: rent,
                    housePrice: housePrice,
                    houseAmount: nftHouseAmount[idRead],
                    //mortgage: nftMortgage[idRead],
                    saleprice: propertySalePrice[idRead],
                    owner: nftOwners[idRead]
                });

                //Sort by zone
                if(idRead > 1)
                {
                    for(uint ixCheck = idRead - 2; ixCheck > 0; ixCheck--)
                    {
                        if( result[ixCheck - 1].zone > result[ixCheck].zone )
                        {
                            //Swap positions
                            PropertyModel memory tmp = result[ixCheck - 1];
                            result[ixCheck - 1] = result[ixCheck];
                            result[ixCheck] = tmp;
                        }
                    }
                }
            }
        }

        return result;
    }

    function getQuote(address source, address destination) public view returns (uint256 value)
    {
        uint256 result;

        if(swapFactory == address(0))
        {
            return result;
        }

        if(source == networkcoinaddress)
        {
            source = chainWrapToken;
        }

        if(destination == networkcoinaddress)
        {
            destination = chainWrapToken;
        }

        address pairLP = IUniswapV2Factory(swapFactory).getPair(source, destination);

        if(pairLP == address(0))
        {
            return result;
        }

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairLP).getReserves();

        if(reserve0 == 0 || reserve1 == 0)
        {
            return result;
        }

        if(IUniswapV2Pair(pairLP).token0() == source)
        {
            result = SafeMath.safeDivFloat(reserve1, reserve0, ERC20(source).decimals());
        }
        else
        {
            result = SafeMath.safeDivFloat(reserve0, reserve1, ERC20(source).decimals());
        }

        return result;
    }

    //Set Attribute Values
    function setOwner(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        owner = newValue;
    }

    function setFeeAndTaxReceiver(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //Transfer NFT ownership
        for(uint idRead = 1; idRead <= id; idRead++)
        {
            if( nftOwners[idRead] == feeandtaxreceiver )
            {
                _transfer(feeandtaxreceiver, newValue, idRead);
            }
        }

        feeandtaxreceiver = newValue;

    }

    function setUSDToken(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        usdToken = newValue;
    }

    function setChainWrapToken(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        chainWrapToken = newValue;
    }

    function setSwapFactory(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        swapFactory = newValue;
    }

    function setMinDeposit(address token, uint256 value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        minDeposit[token] = value;
    }

    function setMinWithdraw(address token, uint256 value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        minWithdraw[token] = value;
    }

    function setNFTURI(string memory newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftURI = newValue;
    }

    function setMaxHouseAmount(uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        maxHouseAmount = newValue;
    }

    function setPrizeWalkAmount(uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        prizeWalkAmount = newValue;
    }

    function setTaxesWalkAmount(uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        taxesWalkAmount = newValue;
    }

    function setTaxesLandMaxPay(uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        taxesLandMaxPay = newValue;
    }

    function setPrizeLandMaxPay(uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        prizeLandMaxPay = newValue;
    }

    function setMinUSDBalanceToWalk(uint256 newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        minUSDBalanceToWalk = newValue;
    }

    function setTokenToPayPrize(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        tokenToPayPrize = newValue;
    }

    function setTokenToCollectTax(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        tokenToCollectTax = newValue;
    }

    function setTokenToUseOnSellPropertyToBank(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        tokenToUseOnSellPropertyToBank = newValue;
    }

    function setNetworkCoinAddress(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        networkcoinaddress = newValue;
    }

    function setDiceFaces(uint value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        diceFaces = value;
    }

    // ***********************************************
    // **************** NFT FUNCTIONS ****************
    // ***********************************************
    function mint(string calldata _nftName, string calldata _nftDescription, string calldata _nftImageURI, uint256 _nftPrice, uint _nftZone) external returns (uint256 tokenId)
    {
        //Only contract owner is able to create properties
        require(msg.sender == owner, 'FN'); //Forbidden

        id = SafeMath.safeAdd(id, 1); //id++

        nftOwners[id] = feeandtaxreceiver; //msg.sender;
        nftName[id] = _nftName;
        nftDescription[id] = _nftDescription;

        if(bytes(_nftImageURI).length == 0)
        {
            nftImageURI[id] = "";
        }
        else
        {
            nftImageURI[id] = _nftImageURI;
        }

        nftPrice[id] = _nftPrice;
        nftZone[id] = _nftZone;
        nftState[id] = 1;
        
        for(uint ixRead = 0; ixRead <= maxHouseAmount + 1; ixRead++) //First is no house and last is hotel
        {
            nftRent[id][ixRead] = SafeMath.safeMul(SafeMath.safeDiv(_nftPrice, 100), SafeMath.safeAdd(ixRead, 1)) ; 

            if(ixRead == 0)
            {
                nftHousePrice[id][ixRead] = 0;
            }
            else
            {
                nftHousePrice[id][ixRead] = SafeMath.safeMul(SafeMath.safeDiv(_nftPrice, 100), SafeMath.safeAdd(ixRead, 60)) ; 
            }
        }

        //nftMortgage[id] = safeDiv(_nftPrice, 2);

        balances[msg.sender] = SafeMath.safeAdd(balances[msg.sender], 1); //balances[msg.sender]++;
        emit Transfer(address(0), msg.sender, id);

        return id;
    }

    function bulkMint(string[] calldata _nftName, string[] calldata _nftDescription, string[] calldata _nftImageURI, uint256[] calldata _nftPrice, uint[] calldata _nftZone) external
    {
        //Only contract owner is able to create properties
        require(msg.sender == owner, 'FN'); //Forbidden

        require(_nftName.length > 0, "Empty list");
        require(_nftName.length == _nftDescription.length && _nftName.length == _nftImageURI.length && _nftName.length == _nftPrice.length, "Invalid Size");

        for(uint ix = 0; ix < _nftName.length; ix++)
        {
            id = SafeMath.safeAdd(id, 1); //id++
            nftOwners[id] = feeandtaxreceiver; //msg.sender;
            nftName[id] = _nftName[ix];
            nftDescription[id] = _nftDescription[ix];

            if(bytes(_nftImageURI[ix]).length == 0)
            {
                nftImageURI[id] = "";
            }
            else
            {
                nftImageURI[id] = _nftImageURI[ix];
            }

            nftPrice[id] = _nftPrice[ix];
            nftState[id] = 1;
            nftZone[id] = _nftZone[ix];

            for(uint ixRead = 0; ixRead <= maxHouseAmount + 1; ixRead++) //First is no house and last is hotel
            {
                nftRent[id][ixRead] = SafeMath.safeMul(SafeMath.safeDiv(_nftPrice[ix], 100), SafeMath.safeAdd(ixRead, 1)) ; 

                if(ixRead == 0)
                {
                    nftHousePrice[id][ixRead] = 0;
                }
                else
                {
                    nftHousePrice[id][ixRead] = SafeMath.safeMul(SafeMath.safeDiv(_nftPrice[ix], 100), SafeMath.safeAdd(ixRead, 60)) ; 
                }
            }

            //nftMortgage[id] = safeDiv(_nftPrice[ix], 2);

            balances[msg.sender] = SafeMath.safeAdd(balances[msg.sender], 1); //balances[msg.sender]++;
            emit Transfer(address(0), msg.sender, id);
        }
    }

    function name() external pure returns (string memory _name) 
    {
        return "Grapenopoly Property";
    }
    
    function symbol() external pure returns (string memory _symbol) 
    {
        return "GRAPEPPT";
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) 
    {
        require(_tokenId <= id, "Invalid NFT ID");
        return Hlp.strConcatenate(Hlp.strConcatenate(Hlp.strConcatenate(Hlp.strConcatenate(nftURI, Hlp.uint2str(block.chainid)), "/"), Hlp.uint2str(_tokenId)), ".json");
    }

    function balanceOf(address _owner) external view returns (uint256)
    {
        require(_owner != address(0), "Zero address is not allowed");
        return balances[_owner];    
    }

    function ownerOf(uint256 _tokenId) external view returns (address)
    {
        return nftOwners[_tokenId];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external
    {
        require(nftOwners[_tokenId] == _from, "Invalid NFT owner");
        require(msg.sender == _from || msg.sender == approvedOperator[_tokenId] || approvedForAll[_from][msg.sender] == true, "Not authorized");
        
        _transfer(_from, _to, _tokenId); 
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external
    {
        require(nftOwners[_tokenId] == _from, "Invalid NFT owner");
        require(msg.sender == _from || msg.sender == approvedOperator[_tokenId] || approvedForAll[_from][msg.sender] == true, "Not authorized");
        
        _transfer(_from, _to, _tokenId); 
        
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "Transfer to non ERC721Receiver implementer");
    }

    function approve(address _to, uint256 _tokenId) external
    {
        address ownerAddr = nftOwners[_tokenId];
        require(msg.sender == owner || approvedForAll[ownerAddr][msg.sender] == true, "Not authorized"); 
        approvedOperator[_tokenId] = _to;
        emit Approval(ownerAddr, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view returns (address)
    {
        return approvedOperator[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) external
    {
        approvedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool)
    {
        return approvedForAll[_owner][_operator];
    }

    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool)
    {
        //return true;
        if (!isContract(_to)) 
        {
            return true;
        }

        //bytes4 retval = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        //return (retval == _ERC721_RECEIVED);

        return (IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) == _ERC721_RECEIVED);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal
    {
        balances[_from] = SafeMath.safeSub(balances[_from], 1); //balances[_from]--
        balances[_to] = SafeMath.safeAdd(balances[_to], 1); //balances[_to]++;
        nftOwners[_tokenId] = _to;
        propertySalePrice[ _tokenId ] = 0; //Remove for SALE board

        emit Transfer(_from, _to, _tokenId);
    }

    function getNFTImage(uint256 _tokenId) public view returns (string memory)
    {
        return bytes(nftImageURI[_tokenId]).length > 0 ? nftImageURI[_tokenId] : Hlp.strConcatenate(Hlp.strConcatenate(Hlp.strConcatenate(Hlp.strConcatenate(nftURI, Hlp.uint2str(block.chainid)), "/"), Hlp.uint2str(_tokenId)), ".png");
    }

    function setNFTName(uint256 _tokenId, string calldata value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftName[_tokenId] = value;
    }

    function setNFTDescription(uint256 _tokenId, string calldata value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftDescription[_tokenId] = value;
    }

    function setNFTImageURI(uint256 _tokenId, string calldata value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftImageURI[_tokenId] = value;
    }

    function setNFTPrice(uint256 _tokenId, uint256 value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftPrice[_tokenId] = value;
    }

    function setNFTState(uint256 _tokenId, uint value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftState[_tokenId] = value;
    }

    function setNFTZone(uint256 _tokenId, uint value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftZone[_tokenId] = value;
    }

    function setNFTRent(uint256 _tokenId, uint rentIndex, uint256 value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(rentIndex <= maxHouseAmount + 1, 'IX'); //Invalid Index
        nftRent[_tokenId][rentIndex] = value;
    }

    function setNFTHousePrice(uint256 _tokenId, uint buildIndex, uint256 value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        require(buildIndex <= maxHouseAmount + 1, 'IX'); //Invalid Index
        nftHousePrice[_tokenId][buildIndex] = value;
    }

/*
    function setNFTMortgage(uint256 _tokenId, uint256 value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        nftMortgage[_tokenId] = value;
        return true;
    }
*/
    // Returns whether the target address is a contract
    function isContract(address account) internal view returns (bool) 
    {
        uint256 size;
        // Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // **************************************************************
    // ********************* POWER UP FUNCTIONS *********************
    // **************************************************************
    function depositPowerUpOnNFT(uint tokenId, address powerToken) external 
    {
        PowerUpRecord memory rec = powerUpRecordList[powerToken];
        require(nftOwners[ tokenId ] == msg.sender, 'own'); //You don't own this property
        require(rec.multiply > 0 && rec.visits > 0, "INIT"); //Initialize required
        require(ERC20(powerToken).allowance(msg.sender, address(this)) >= ONE, "PA"); //Check the Powerup Token allowance. Use approve function.
        require(depositedPowerup[tokenId][powerToken] == 0, "ADDED"); //Already added

        ERC20(powerToken).transferFrom(msg.sender, feeandtaxreceiver, ONE);

        depositedPowerup[tokenId][powerToken] = 1;
        depositedPowerupVisits[tokenId][powerToken] = 0;
    }

    // ******************** GET VALUES ********************
    function getPowerUpMultiply(address powerToken) external view returns (uint)
    {
        return powerUpRecordList[powerToken].multiply;
    }

    function getPowerUpVisits(address powerToken) external view returns (uint)
    {
        return powerUpRecordList[powerToken].visits;
    }

    // *********************  STATUS  *********************
    function isPowerUpDepositedOnNFT(uint tokenId, address powerToken) external view returns (uint)
    {
        return depositedPowerup[tokenId][powerToken];
    }

    function getPowerUpOnNFTVisits(uint tokenId, address powerToken) external view returns (uint)
    {
        return depositedPowerupVisits[tokenId][powerToken];
    }


    // ******************** SET VALUES ********************
    function setPowerUPOnNFTVisits(uint tokenId) internal returns (uint)
    {
        uint multiplyResult = 1;
        for(uint seed = 0; seed < powerUpIdSeed; seed++)
        {
            address addr = powerUpAddresses[seed];
            PowerUpRecord memory rec = powerUpRecordList[addr];

            if(depositedPowerup[tokenId][addr] == 0)
            {
                continue;
            }

            multiplyResult = SafeMath.safeMul(multiplyResult, rec.multiply);

            //depositedPowerupVisits[tokenId][addr] = SafeMath.safeAdd(depositedPowerupVisits[tokenId][addr], 1);
            depositedPowerupVisits[tokenId][addr]++;


            //Check run out visits
            if(depositedPowerupVisits[tokenId][addr] >= rec.visits)
            {
                depositedPowerup[tokenId][addr] = 0;
                depositedPowerupVisits[tokenId][addr] = 0;
            }

        }

        return multiplyResult;
    }

    // ******************* ADMIN SETUP ********************
    function setPowerUpToken(address powerToken, uint multiply, uint visits) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        //If is first time (zeroes), add to token list
        if(powerUpRecordList[powerToken].multiply == 0 && powerUpRecordList[powerToken].visits == 0)
        {
            powerUpAddresses[powerUpIdSeed] = powerToken;
            powerUpIdSeed = SafeMath.safeAdd(powerUpIdSeed, 1); 
        }

        powerUpRecordList[powerToken].multiply = multiply;
        powerUpRecordList[powerToken].visits = visits;
    }
}

// ****************************************************
// ***************** HELPER FUNCTIONS *****************
// ****************************************************
library Hlp 
{

    function getFace(uint nc, uint total) internal view returns (uint)
    {
        return SafeMath.safeAdd(Hlp.clockN(SafeMath.safeMul(nc, 3), total), 1);
    }

    function sortZone(uint256 id, mapping(uint256 => uint) storage nftZone) internal view returns (uint[] memory)
    {
        uint[] memory result = new uint[]( id );
        uint[] memory resultZone = new uint[]( id );

        if(id > 0)
        {
            for(uint idRead = 1; idRead <= id; idRead++)
            {
                //Insert property
                result[idRead - 1] = idRead;
                resultZone[idRead - 1] = nftZone[idRead];

                //Sort by zone
                if(idRead > 1)
                {
                    for(uint ixCheck = idRead - 2; ixCheck > 0; ixCheck--)
                    {
                        if( resultZone[ixCheck - 1] > resultZone[ixCheck] )
                        {
                            //Swap positions
                            uint tmp = result[ixCheck - 1];
                            result[ixCheck - 1] = result[ixCheck];
                            result[ixCheck] = tmp;

                            tmp = resultZone[ixCheck - 1];
                            resultZone[ixCheck - 1] = resultZone[ixCheck];
                            resultZone[ixCheck] = tmp;
                        }
                    }
                }
            }
        }

        return result;
    }

    function strConcatenate(string memory s1, string memory s2) internal pure returns (string memory) 
    {
        return string(abi.encodePacked(s1, s2));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) 
    {
        if (_i == 0) 
        {
            return "0";
        }

        uint j = _i;
        uint len;

        while (j != 0) 
        {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint k = len;

        while (_i != 0) 
        {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
    }

    function clockN(uint nc, uint ma) internal view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(SafeMath.safeAdd(block.timestamp, nc), block.difficulty, msg.sender))) % ma;
    }
}

// *****************************************************
// **************** SAFE MATH FUNCTIONS ****************
// *****************************************************
library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        require(c >= a, "OADD"); //STAKE: SafeMath: addition overflow

        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeSub(a, b, "OSUB"); //STAKE: subtraction overflow
    }

    function safeSub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) 
        {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "OMUL"); //STAKE: multiplication overflow

        return c;
    }

    function safeMulFloat(uint256 a, uint256 b, uint decimals) internal pure returns(uint256)
    {
        if (a == 0 || decimals == 0)  
        {
            return 0;
        }

        uint result = safeDiv(safeMul(a, b), safePow(10, uint256(decimals)));

        return result;
    }

    function safePow(uint256 n, uint256 e) internal pure returns(uint256)
    {

        if (e == 0) 
        {
            return 1;
        } 
        else if (e == 1) 
        {
            return n;
        } 
        else 
        {
            uint256 p = safePow(n,  safeDiv(e, 2));
            p = safeMul(p, p);

            if (safeMod(e, 2) == 1) 
            {
                p = safeMul(p, n);
            }

            return p;
        }
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeDiv(a, b, "ZDIV"); //STAKE: division by zero
    }

    function safeDiv(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function safeDivFloat(uint256 a, uint256 b, uint256 decimals) internal pure returns (uint256)
    {
        return safeDiv(safeMul(a, safePow(10,decimals)), b);
    }

    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return safeMod(a, b, "ZMOD"); //STAKE: modulo by zero
    }

    function safeMod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) 
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}