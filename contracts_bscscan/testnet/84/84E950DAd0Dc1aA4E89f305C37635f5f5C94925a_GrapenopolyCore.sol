/**
 *Submitted for verification at BscScan.com on 2021-08-13
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

interface IGrapenopoly {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getNFTPrice(uint256 _tokenId) external view returns (uint256);
    function getNFTHouseAmount(uint256 _tokenId) external view returns (uint);
    function getNFTHousePrice(uint256 _tokenId, uint buildIndex) external view returns (uint256);
    //function razeHouseOrHotelPropertySell(uint256 _tokenId) external;
    function getNFTRent(uint256 _tokenId, uint rentIndex) external view returns (uint256);
    function getLastGeneratedId() external view returns (uint256);
    function getNFTZone(uint256 _tokenId) external view returns (uint);
    function getNFTName(uint256 _tokenId) external view returns (string memory);
    function getNFTDescription(uint256 _tokenId) external view returns (string memory);
    function getNFTImage(uint256 _tokenId) external view returns (string memory);
    function getNFTState(uint256 _tokenId) external view returns (uint);
    function getNFTMortgage(uint256 _tokenId) external view returns (uint256);
}

contract GrapenopolyCore
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
        uint256 mortgage;
        uint256 saleprice;
        address owner;
    }

    struct DiceResult {
        uint[] faces;
        uint steps;
        uint256 collectedPrize;
        uint256 paidTaxes;
        uint256 paidRent;
    }

    // Game Properties
    address private grapenopolyContract;
    address private networkcoinaddress;
    address private owner;
    address private feeandtaxreceiver;
    uint private totalDices;
    uint private diceFaces;
    uint private diceNonce;
    uint private prizeNonce;
    uint256 private MAX_NONCE;
    uint private maxHouseAmount;
    uint private prizeWalkAmount;
    uint private taxesWalkAmount;
    uint private prizeLandMaxPay;
    uint private taxesLandMaxPay;
    uint private minUSDBalanceToWalk;
    address private tokenToPayPrize;
    address private tokenToCollectTax;
    address private tokenToUseOnSellPropertyToBank;
    address private usdToken;
    address private chainWrapToken;
    address private swapFactory;

    //General Info
    mapping(address => uint256) private playerPosition;
    mapping(address => uint) private playerAccumulatedStepsFromLastTax;
    mapping(address => uint) private playerAccumulatedStepsFromLastPrize;

    mapping(uint256 => uint) private propertySalePrice; //Property For Sale defined by NFT Owner | 0 = Not for sale

    //Min Deposit for each Token
    mapping(address => uint256) private minDeposit;

    //Min Withdraw for each Token
    mapping(address => uint256) private minWithdraw;

    //User lists (1st mapping user, 2nd mapping token)
    mapping(address => mapping(address => uint256)) private vaultBalances;

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
        //Game Startup Attributes
        owner = msg.sender;
        diceNonce = 29689;
        prizeNonce = 3711;
        MAX_NONCE = 237512;
    }

    // ************************************************
    // *********** MAIN GAME FUNCTIONS ****************
    // ************************************************
    function getPlayerPosition(address player) external view returns (uint256)
    {
        return playerPosition[player];
    }

    function getVaultBalance(address player, address tokenAddress) external view returns (uint256)
    {
        return vaultBalances[player][tokenAddress];
    }


    function putUpPropertyForSale(uint256 _tokenId, uint256 salePrice) external
    {
        require(msg.sender == IGrapenopoly(grapenopolyContract).ownerOf(_tokenId) || msg.sender == owner, 'FN'); //Forbidden

        //Commented below: Zero remove sale offer
        //require(salePrice > 0, 'zero'); //Price must be greather than zero

        propertySalePrice[ _tokenId ] = salePrice;
    }

    function getPropertySalePrice(uint256 _tokenId) external view returns (uint256)
    {
        return propertySalePrice[ _tokenId ];
    }

    function depositToken(ERC20 token, uint256 amountInWei) external 
    {
        address tokenAddress = address(token);

        //Approve (outside): allowed[msg.sender][spender] (sender = my account, spender = token address)
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amountInWei, "AL"); //VAULT: Check the token allowance. Use approve function.

        require(amountInWei >= minDeposit[address(token)], "DL"); //VAULT: Deposit value is too low.

        token.transferFrom(msg.sender, address(this), amountInWei);

        uint256 currentTotal = vaultBalances[msg.sender][tokenAddress];

        //Increase/register deposit balance
        vaultBalances[msg.sender][tokenAddress] = safeAdd(currentTotal, amountInWei);

        emit OnDeposit(msg.sender, tokenAddress, amountInWei);
    }

    function depositNetworkCoin() external payable 
    {
        require(msg.value > 0, "DL"); //VAULT: Deposit value is too low.

        require(msg.value >= minDeposit[networkcoinaddress], "DL"); //VAULT: Deposit value is too low.

        uint256 currentTotal = vaultBalances[msg.sender][networkcoinaddress];

        //Increase/register deposit balance
        vaultBalances[msg.sender][networkcoinaddress] = safeAdd(currentTotal, msg.value);

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
            vaultBalances[player][token] = safeSub(currentTotal, amountInWei);
        }

        emit OnWithdraw(player, token, amountInWei);
    }

    function buyPropertyFromBankBack(uint256 _tokenId, address selectedTokenToPay) external
    {
        require(IGrapenopoly(grapenopolyContract).ownerOf(_tokenId) == feeandtaxreceiver, 'bk'); //Must be a bank property
        //require(vaultBalances[msg.sender][selectedTokenToPay] > 0, "NB"); //No balance for purchase
        require(vaultBalances[msg.sender][selectedTokenToPay] >= safeMulFloat(IGrapenopoly(grapenopolyContract).getNFTPrice(_tokenId), getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()), "NB"); //No balance for purchase
        require(playerPosition[msg.sender] == _tokenId, 'ip'); //Invalid player position

        //Subtract amount of user balance
        vaultBalances[msg.sender][selectedTokenToPay] = safeSub(vaultBalances[msg.sender][selectedTokenToPay], safeMulFloat(IGrapenopoly(grapenopolyContract).getNFTPrice(_tokenId), getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()) );

        emit OnBuyPropertyFromBank(_tokenId, selectedTokenToPay);
    }

    function buyPropertyForSaleBack(uint256 _tokenId, address selectedTokenToPay) external
    {
        require(propertySalePrice[ _tokenId ] > 0, 'N'); //Not for sale
        require(IGrapenopoly(grapenopolyContract).ownerOf( _tokenId ) != feeandtaxreceiver, 'bk'); //Bank is the property owner
        require(IGrapenopoly(grapenopolyContract).ownerOf( _tokenId ) != msg.sender, 'O'); //Owned: You are the owner
        require(vaultBalances[msg.sender][selectedTokenToPay] >= safeMulFloat(propertySalePrice[ _tokenId ], getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()), "NB"); //No balance for purchase
        require(playerPosition[msg.sender] == _tokenId, 'ip'); //Invalid player position

        //*** Pay to Owner ***
        //Subtract amount of user balance
        vaultBalances[msg.sender][selectedTokenToPay] = safeSub(vaultBalances[msg.sender][selectedTokenToPay], safeMulFloat(propertySalePrice[ _tokenId ], getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()) );

        //Add amount to NFT owner
        vaultBalances[ IGrapenopoly(grapenopolyContract).ownerOf( _tokenId ) ][selectedTokenToPay] = safeAdd(vaultBalances[ IGrapenopoly(grapenopolyContract).ownerOf(_tokenId) ][selectedTokenToPay], safeMulFloat(propertySalePrice[ _tokenId ], getQuote(usdToken, selectedTokenToPay), ERC20(usdToken).decimals()));

        emit OnBuyPropertyForSale(_tokenId, selectedTokenToPay, propertySalePrice[ _tokenId ]);
    }

    function buyHouseOrHotelForPropertyBack(uint256 _tokenId, address selectedTokenToPayBuild) external
    {
        //Price: nftHousePrice[_tokenId][buildIndex]
        //Next Build Index: safeAdd(nftHouseAmount[ _tokenId ], 1);

        require(IGrapenopoly(grapenopolyContract).getNFTHouseAmount(_tokenId) < safeAdd(maxHouseAmount, 1), 'mx'); //Maximum builds reached
        require(IGrapenopoly(grapenopolyContract).ownerOf(_tokenId) == msg.sender, 'own'); //You don't own this property
        require(safeMulFloat(vaultBalances[msg.sender][selectedTokenToPayBuild], getQuote(usdToken, selectedTokenToPayBuild), ERC20(usdToken).decimals()) >= IGrapenopoly(grapenopolyContract).getNFTHousePrice(_tokenId, safeAdd( IGrapenopoly(grapenopolyContract).getNFTHouseAmount(_tokenId), 1 ) ), "NB"); //No balance to build

        //Pay for the house or hotel
        vaultBalances[msg.sender][selectedTokenToPayBuild] = safeSub(vaultBalances[msg.sender][selectedTokenToPayBuild], IGrapenopoly(grapenopolyContract).getNFTHousePrice(_tokenId, safeAdd( IGrapenopoly(grapenopolyContract).getNFTHouseAmount(_tokenId), 1 ) ));

        emit OnHouseOrHotelBuy(_tokenId, selectedTokenToPayBuild, IGrapenopoly(grapenopolyContract).getNFTHouseAmount(_tokenId));
    }

    function sellHouseOrHotelProperty(uint256 _tokenId) external
    {
        require(IGrapenopoly(grapenopolyContract).ownerOf(_tokenId) == msg.sender, 'own'); //You don't own this property
        require(IGrapenopoly(grapenopolyContract).getNFTHouseAmount(_tokenId) > 0, 'nh'); //No house to sell

        //Receive for house or hotel selling
        vaultBalances[msg.sender][tokenToUseOnSellPropertyToBank] = safeAdd( vaultBalances[msg.sender][tokenToUseOnSellPropertyToBank], IGrapenopoly(grapenopolyContract).getNFTHousePrice(_tokenId, IGrapenopoly(grapenopolyContract).getNFTHouseAmount( _tokenId )) );

        emit OnHouseOrHotelSell(_tokenId, tokenToUseOnSellPropertyToBank, IGrapenopoly(grapenopolyContract).getNFTHouseAmount(_tokenId) );

        //Update build index
        //IGrapenopoly(grapenopolyContract).razeHouseOrHotelPropertySell(_tokenId);
        bool status;
        bytes memory result;
        (status, result) = grapenopolyContract.delegatecall(abi.encodePacked(bytes4(keccak256("razeHouseOrHotelPropertySell(uint256)")), _tokenId));
    }

    function getQuote(address source, address destination) public view returns (uint256)
    {
        uint256 result = 0;
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
            result = safeDivFloat(reserve1, reserve0, ERC20(source).decimals());
        }
        else
        {
            result = safeDivFloat(reserve0, reserve1, ERC20(source).decimals());
        }

        return result;
    }

    function rollDices(address selectedTokenToPayRent) external
    {
        require(safeMulFloat(vaultBalances[msg.sender][selectedTokenToPayRent], getQuote(usdToken, selectedTokenToPayRent), ERC20(usdToken).decimals()) >= minUSDBalanceToWalk, "NB"); //No balances for moving
        require(IGrapenopoly(grapenopolyContract).getLastGeneratedId() > safeMul(totalDices, diceFaces), "LP" ); //Low properties for dices rolling
        require(vaultBalances[msg.sender][tokenToCollectTax] >= taxesLandMaxPay, "LTB"); //Low tax balance: You must be prepared to pay maximum tax before walk

        uint[] memory faces = new uint[](totalDices);

        DiceResult memory result;
        uint walkSteps = 0;

        for(uint ix = 0; ix < totalDices; ix++)
        {
            faces[ix] = getDiceFace();
            walkSteps = safeAdd(walkSteps, faces[ix]);
        }

        result.faces = faces;
        result.steps = walkSteps;
        result.collectedPrize = 0;
        result.paidTaxes = 0;
        result.paidRent = 0;

        uint[] memory propList = getPropertyIdList();
        
        uint currentPlayerPositionIndex = 0;
        uint newPlayerPositionIndex = 0;
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
        if(safeAdd(currentPlayerPositionIndex, walkSteps) > propList.length - 1)
        {
            newPlayerPositionIndex = safeSub(safeAdd(currentPlayerPositionIndex, walkSteps), propList.length);
        }
        else
        {
            newPlayerPositionIndex = safeAdd(currentPlayerPositionIndex, walkSteps);
        }

        playerPosition[msg.sender] = propList[newPlayerPositionIndex];

        //Update accumulated steps
        playerAccumulatedStepsFromLastTax[msg.sender] = safeAdd(playerAccumulatedStepsFromLastTax[msg.sender], walkSteps);
        playerAccumulatedStepsFromLastPrize[msg.sender] = safeAdd(playerAccumulatedStepsFromLastPrize[msg.sender], walkSteps);

        if(prizeWalkAmount > 0 && playerAccumulatedStepsFromLastPrize[msg.sender] >= prizeWalkAmount)
        {
            //Reset accumalated steps
            playerAccumulatedStepsFromLastPrize[msg.sender] = safeSub(playerAccumulatedStepsFromLastPrize[msg.sender], taxesWalkAmount);

            //Collect prize
            uint256 prizeValue = uint256(keccak256(abi.encodePacked(safeAdd(block.timestamp, safeMul(prizeNonce, 7)), block.difficulty, msg.sender))) % prizeLandMaxPay;
            if(safeAdd(prizeNonce, 1) >= MAX_NONCE)
            {
                prizeNonce = 0;
            }
            prizeNonce++;

            if(prizeValue > 0)
            {
                vaultBalances[msg.sender][tokenToPayPrize] = safeAdd(vaultBalances[msg.sender][tokenToPayPrize], prizeValue);
                result.collectedPrize = prizeValue;
            }
        }

        if(taxesWalkAmount > 0 && playerAccumulatedStepsFromLastTax[msg.sender] >= taxesWalkAmount)
        {
            //Reset accumalated steps
            playerAccumulatedStepsFromLastTax[msg.sender] = safeSub(playerAccumulatedStepsFromLastTax[msg.sender], taxesWalkAmount);

            //Pay tax
            uint256 taxValue = uint256(keccak256(abi.encodePacked(safeAdd(block.timestamp, safeMul(prizeNonce, 5)), block.difficulty, msg.sender))) % taxesLandMaxPay;
            if(safeAdd(prizeNonce, 1) >= MAX_NONCE)
            {
                prizeNonce = 0;
            }
            prizeNonce++;

            if(taxValue > 0)
            {
                if(vaultBalances[msg.sender][tokenToCollectTax] > taxValue)
                {
                    result.paidTaxes = taxValue;
                    vaultBalances[msg.sender][tokenToCollectTax] = safeSub(vaultBalances[msg.sender][tokenToCollectTax], taxValue);
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
        if( IGrapenopoly(grapenopolyContract).ownerOf( playerPosition[msg.sender] ) != msg.sender && IGrapenopoly(grapenopolyContract).ownerOf( playerPosition[msg.sender] ) != feeandtaxreceiver)
        {
            //Convert rent from USD to token to pay rent
            uint houseAmount = IGrapenopoly(grapenopolyContract).getNFTHouseAmount( playerPosition[msg.sender] );
            if(houseAmount > maxHouseAmount + 1)
            {
                houseAmount = maxHouseAmount + 1;
            }

            ///uint256 rentValueInUSD = nftRent[ playerPosition[msg.sender] ][ houseAmount ];
            if(IGrapenopoly(grapenopolyContract).getNFTRent(playerPosition[msg.sender], houseAmount) > 0)
            {
                uint256 rentValueInToken = safeMulFloat(IGrapenopoly(grapenopolyContract).getNFTRent(playerPosition[msg.sender], houseAmount), getQuote(usdToken, selectedTokenToPayRent), ERC20(usdToken).decimals());
                if(rentValueInToken > 0)
                {
                    if(vaultBalances[msg.sender][selectedTokenToPayRent] >= rentValueInToken)
                    {
                        //Pay rent to nftOwner
                        vaultBalances[msg.sender][selectedTokenToPayRent] = safeSub(vaultBalances[msg.sender][selectedTokenToPayRent], rentValueInToken);
                        vaultBalances[ IGrapenopoly(grapenopolyContract).ownerOf( playerPosition[msg.sender] ) ][selectedTokenToPayRent] = safeAdd(vaultBalances[ IGrapenopoly(grapenopolyContract).ownerOf( playerPosition[msg.sender] ) ][selectedTokenToPayRent], rentValueInToken);
                        result.paidRent = rentValueInToken;
                    }
                    else
                    {
                        //Player bankrupt: Not enough to pay rent, player his amount and is stopped
                        uint256 willingToPay = safeSub(rentValueInToken, vaultBalances[msg.sender][selectedTokenToPayRent]);
                        
                        //Pay rent to nftOwner
                        vaultBalances[msg.sender][selectedTokenToPayRent] = 0;
                        vaultBalances[ IGrapenopoly(grapenopolyContract).ownerOf( playerPosition[msg.sender] ) ][selectedTokenToPayRent] = willingToPay;
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

    function getDiceFace() private returns(uint)
    {
        uint vFace = uint(keccak256(abi.encodePacked(
            safeAdd(block.timestamp, safeMul(diceNonce, 3) ), 
            block.difficulty, 
            msg.sender)
        )) % diceFaces;

        vFace = safeAdd(vFace, 1);

        if(safeAdd(diceNonce, 1) >= MAX_NONCE)
        {
            diceNonce = 0;
        }
        
        diceNonce++;

        return vFace;
    }

    function getPropertyIdList() internal view returns (uint[] memory)
    {
        uint[] memory result = new uint[]( IGrapenopoly(grapenopolyContract).getLastGeneratedId() );
        uint[] memory resultZone = new uint[]( IGrapenopoly(grapenopolyContract).getLastGeneratedId() );

        if(IGrapenopoly(grapenopolyContract).getLastGeneratedId() > 0)
        {
            for(uint idRead = 1; idRead <= IGrapenopoly(grapenopolyContract).getLastGeneratedId(); idRead++)
            {
                //Insert property
                result[idRead - 1] = idRead;
                resultZone[idRead - 1] = IGrapenopoly(grapenopolyContract).getNFTZone(idRead);

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

    function getPropertyList() external view returns (PropertyModel[] memory)
    {
        PropertyModel[] memory result = new PropertyModel[]( IGrapenopoly(grapenopolyContract).getLastGeneratedId() );

        if(IGrapenopoly(grapenopolyContract).getLastGeneratedId() > 0)
        {
            for(uint idRead = 1; idRead <= IGrapenopoly(grapenopolyContract).getLastGeneratedId(); idRead++)
            {
                uint256[] memory rent = new uint256[](maxHouseAmount + 2);
                uint256[] memory housePrice = new uint256[](maxHouseAmount + 2);

                for(uint ixRent = 0; ixRent <= maxHouseAmount + 1; ixRent++)
                {
                    rent[ixRent] = IGrapenopoly(grapenopolyContract).getNFTRent(idRead, ixRent); //First is no house and last is hotel
                    housePrice[ixRent] = IGrapenopoly(grapenopolyContract).getNFTHousePrice(idRead, ixRent); //First is no house (zero) and last is hotel
                }

                //Insert property
                result[idRead - 1] = PropertyModel({
                    id: idRead,
                    name: IGrapenopoly(grapenopolyContract).getNFTName(idRead),
                    description: IGrapenopoly(grapenopolyContract).getNFTDescription(idRead),
                    imageURI: IGrapenopoly(grapenopolyContract).getNFTImage(idRead),
                    price: IGrapenopoly(grapenopolyContract).getNFTPrice(idRead),
                    state: IGrapenopoly(grapenopolyContract).getNFTState(idRead),
                    zone: IGrapenopoly(grapenopolyContract).getNFTZone(idRead),
                    rent: rent,
                    housePrice: housePrice,
                    houseAmount: IGrapenopoly(grapenopolyContract).getNFTHouseAmount(idRead),
                    mortgage: IGrapenopoly(grapenopolyContract).getNFTMortgage(idRead),
                    saleprice: propertySalePrice[idRead],
                    owner: IGrapenopoly(grapenopolyContract).ownerOf(idRead)
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

    function getPlayerBalance(address player, address token) external view returns (uint256 value)
    {
        return vaultBalances[player][token];
    }

    // ************************************************
    // **************** SET ATTRIBUTES ****************
    // ************************************************
    function setGrapenopolyContract(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        grapenopolyContract = newValue;
    }

    function setOwner(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        owner = newValue;
    }

    function setNetworkCoinAddress(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        networkcoinaddress = newValue;
    }

    function setFeeAndTaxReceiver(address newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden

        feeandtaxreceiver = newValue;
    }

    function setTotalDices(uint value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        totalDices = value;
    }

    function setDiceFaces(uint value) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        diceFaces = value;
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

    function setPrizeLandMaxPay(uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        prizeLandMaxPay = newValue;
    }

    function setTaxesLandMaxPay(uint newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        taxesLandMaxPay = newValue;
    }

    function setMinUSDBalanceToWalk(uint256 newValue) external
    {
        require(msg.sender == owner, 'FN'); //Forbidden
        minUSDBalanceToWalk = newValue;
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
        minDeposit[token] = value;
    }

    function setMinWithdraw(address token, uint256 value) external
    {
        minWithdraw[token] = value;
    }

    // ************************************************
    // **************** GET ATTRIBUTES ****************
    // ************************************************
    function getGrapenopolyContract() external view returns (address)
    {
        return grapenopolyContract;
    }

    function getOwner() external view returns (address)
    {
        return owner;
    }

    function getNetworkCoinAddress() external view returns (address)
    {
        return networkcoinaddress;
    }

    function getFeeAndTaxReceiver() external view returns (address)
    {
        return feeandtaxreceiver;
    }

    function getTotalDices() external view returns (uint)
    {
        return totalDices;
    }

    function getDiceFaces() external view returns (uint)
    {
        return diceFaces;
    }

    function getMaxHouseAmount() external view returns (uint)
    {
        return maxHouseAmount;
    }

    function getPrizeWalkAmount() external view returns (uint)
    {
        return prizeWalkAmount;
    }

    function getTaxesWalkAmount() external view returns (uint)
    {
        return taxesWalkAmount;
    }

    function getTokenToPayPrize() external view returns (address)
    {
        return tokenToPayPrize;
    }

    function getTokenToCollectTax() external view returns (address)
    {
        return tokenToCollectTax;
    }

    function getTokenToUseOnSellPropertyToBank() external view returns (address)
    {
        return tokenToUseOnSellPropertyToBank;
    }

    function getPrizeLandMaxPay() external view returns (uint)
    {
        return prizeLandMaxPay;
    }

    function getTaxesLandMaxPay() external view returns (uint)
    {
        return taxesLandMaxPay;
    }

    function getMinUSDBalanceToWalk() external view returns (uint256)
    {
        return minUSDBalanceToWalk;
    }

    function getUSDToken() external view returns (address)
    {
        return usdToken;
    }

    function getChainWrapToken() external view returns (address)
    {
        return chainWrapToken;
    }

    function getSwapFactory() external view returns (address)
    {
        return swapFactory;
    }

    function getMinDeposit(address token) external view returns (uint256)
    {
        return minDeposit[token];
    }

    function getMinWithdraw(address token) external view returns (uint256)
    {
        return minWithdraw[token];
    }



    // *****************************************************
    // **************** SAFE MATH FUNCTIONS ****************
    // *****************************************************
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