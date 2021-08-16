pragma solidity 0.5.17;

import "./MToken.sol";
import "./MomaMasterStorage.sol";
import "./MomaFactoryInterface.sol";

/**
 * @title Moma's Token Farming Contract
 * @author moma
 */
 
contract FarmingDelegate is MomaMasterV1Storage, MomaMasterErrorReporter, ExponentialNoError {

    /// @notice Emitted when a new token speed is updated for a market
    event TokenSpeedUpdated(address indexed token, MToken indexed mToken, uint oldSpeed, uint newSpeed);

    /// @notice Emitted when token is distributed to a supplier
    event DistributedSupplierToken(address indexed token, MToken indexed mToken, address indexed supplier, uint tokenDelta, uint tokenSupplyIndex);

    /// @notice Emitted when token is distributed to a borrower
    event DistributedBorrowerToken(address indexed token, MToken indexed mToken, address indexed borrower, uint tokenDelta, uint tokenBorrowIndex);

    /// @notice Emitted when token is claimed by user
    event TokenClaimed(address indexed token, address indexed user, uint accrued, uint claimed, uint notClaimed);

    /// @notice Emitted when token farm is updated by admin
     event TokenFarmUpdated(EIP20Interface token, uint oldStart, uint oldEnd, uint newStart, uint newEnd);

    /// @notice Emitted when a new token market is added to momaMarkets
    event NewTokenMarket(address indexed token, MToken indexed mToken);

    /// @notice Emitted when token is granted by admin
    event TokenGranted(address token, address recipient, uint amount);

    /// @notice The initial moma index for a market
    uint224 public constant momaInitialIndex = 1e36;

    bool public constant isFarmingDelegate = true;


    /*** Tokens Farming Internal Functions ***/

    /**
     * @notice Calculates the new token supply index and block
     * @dev Non-token market will return (0, blockNumber). To avoid revert: no over/underflow
     * @param token The token whose supply index to calculate
     * @param mToken The market whose supply index to calculate
     * @return (new index, new block)
     */
    function newTokenSupplyIndexInternal(address token, address mToken) internal view returns (uint224, uint32) {
        MarketState storage supplyState = farmStates[token].supplyState[mToken];
        uint224 _index = supplyState.index;
        uint32 _block = supplyState.block;
        uint blockNumber = getBlockNumber();
        uint32 endBlock = farmStates[token].endBlock;

        if (blockNumber > uint(_block) && blockNumber > uint(farmStates[token].startBlock) && _block < endBlock) {
            uint supplySpeed = farmStates[token].speeds[mToken];
            // if (farmStates[token].startBlock > _block) _block = farmStates[token].startBlock; // we make sure _block >= startBlock
            if (blockNumber > uint(endBlock)) blockNumber = uint(endBlock);
            uint deltaBlocks = sub_(blockNumber, uint(_block)); // deltaBlocks will always > 0
            uint tokenAccrued = mul_(deltaBlocks, supplySpeed);
            uint supplyTokens = MToken(mToken).totalSupply();
            Double memory ratio = supplyTokens > 0 ? fraction(tokenAccrued, supplyTokens) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: _index}), ratio);
            _index = safe224(index.mantissa, "new index exceeds 224 bits");
            _block = safe32(blockNumber, "block number exceeds 32 bits");
        }
        return (_index, _block);
    }

    /**
     * @notice Accrue token to the market by updating the supply index
     * @dev To avoid revert: no over/underflow
     * @param token The token whose supply index to update
     * @param mToken The market whose supply index to update
     */
    function updateTokenSupplyIndexInternal(address token, address mToken) internal {
        // Non-token market's speed will always be 0, 0 speed token market will also update nothing
        if (farmStates[token].speeds[mToken] > 0) {
            (uint224 _index, uint32 _block) = newTokenSupplyIndexInternal(token, mToken);

            MarketState storage supplyState = farmStates[token].supplyState[mToken];
            supplyState.index = _index;
            supplyState.block = _block;
        }
    }

    /**
     * @notice Calculates the new token borrow index and block
     * @dev Non-token market will return (0, blockNumber). To avoid revert: marketBorrowIndex > 0
     * @param token The token whose borrow index to calculate
     * @param mToken The market whose borrow index to calculate
     * @param marketBorrowIndex The market borrow index
     * @return (new index, new block)
     */
    function newTokenBorrowIndexInternal(address token, address mToken, uint marketBorrowIndex) internal view returns (uint224, uint32) {
        MarketState storage borrowState = farmStates[token].borrowState[mToken];
        uint224 _index = borrowState.index;
        uint32 _block = borrowState.block;
        uint blockNumber = getBlockNumber();
        uint32 endBlock = farmStates[token].endBlock;

        if (blockNumber > uint(_block) && blockNumber > uint(farmStates[token].startBlock) && _block < endBlock) {
            uint borrowSpeed = farmStates[token].speeds[mToken];
            // if (farmStates[token].startBlock > _block) _block = farmStates[token].startBlock; // we make sure _block >= startBlock
            if (blockNumber > uint(endBlock)) blockNumber = uint(endBlock);
            uint deltaBlocks = sub_(blockNumber, uint(_block)); // deltaBlocks will always > 0
            uint tokenAccrued = mul_(deltaBlocks, borrowSpeed);
            uint borrowAmount = div_(MToken(mToken).totalBorrows(), Exp({mantissa: marketBorrowIndex}));
            Double memory ratio = borrowAmount > 0 ? fraction(tokenAccrued, borrowAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: _index}), ratio);
            _index = safe224(index.mantissa, "new index exceeds 224 bits");
            _block = safe32(blockNumber, "block number exceeds 32 bits");
        }
        return (_index, _block);
    }

    /**
     * @notice Accrue token to the market by updating the borrow index
     * @dev To avoid revert: no over/underflow
     * @param token The token whose borrow index to update
     * @param mToken The market whose borrow index to update
     * @param marketBorrowIndex The market borrow index
     */
    function updateTokenBorrowIndexInternal(address token, address mToken, uint marketBorrowIndex) internal {
        // Non-token market's speed will always be 0, 0 speed token market will also update nothing
        if (isLendingPool == true && farmStates[token].speeds[mToken] > 0 && marketBorrowIndex > 0) {
            (uint224 _index, uint32 _block) = newTokenBorrowIndexInternal(token, mToken, marketBorrowIndex);
            
            MarketState storage borrowState = farmStates[token].borrowState[mToken];
            borrowState.index = _index;
            borrowState.block = _block;
        }
    }

    /**
     * @notice Calculates token accrued by a supplier
     * @dev To avoid revert: no over/underflow
     * @param token The token in which the supplier is interacting
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute token to
     * @param supplyIndex The token supply index of this market in Double type
     * @return (new supplierAccrued, new supplierDelta)
     */
    function newSupplierTokenInternal(address token, address mToken, address supplier, Double memory supplyIndex) internal view returns (uint, uint) {
        TokenFarmState storage state = farmStates[token];
        Double memory supplierIndex = Double({mantissa: state.supplierIndex[mToken][supplier]});
        uint _supplierAccrued = state.accrued[supplier];
        uint supplierDelta = 0;

        // supply before set token market can still get rewards start from set block or startBlock
        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = momaInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = MToken(mToken).balanceOf(supplier);
        supplierDelta = mul_(supplierTokens, deltaIndex);
        _supplierAccrued = add_(_supplierAccrued, supplierDelta);
        return (_supplierAccrued, supplierDelta);
    }

    /**
     * @notice Distribute token accrued by a supplier
     * @dev To avoid revert: no over/underflow
     * @param token The token in which the supplier is interacting
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute token to
     */
    function distributeSupplierTokenInternal(address token, address mToken, address supplier) internal {
        TokenFarmState storage state = farmStates[token];
        if (state.supplyState[mToken].index > state.supplierIndex[mToken][supplier]) {
            Double memory supplyIndex = Double({mantissa: state.supplyState[mToken].index});
            (uint _supplierAccrued, uint supplierDelta) = newSupplierTokenInternal(token, mToken, supplier, supplyIndex);

            state.supplierIndex[mToken][supplier] = supplyIndex.mantissa;
            state.accrued[supplier] = _supplierAccrued;
            emit DistributedSupplierToken(token, MToken(mToken), supplier, supplierDelta, supplyIndex.mantissa);
        }
    }

    /**
     * @notice Calculate token accrued by a borrower
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @dev To avoid revert: marketBorrowIndex > 0
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute token to
     * @param marketBorrowIndex The market borrow index
     * @param borrowIndex The token borrow index of this market in Double type
     * @return (new borrowerAccrued, new borrowerDelta)
     */
    function newBorrowerTokenInternal(address token, address mToken, address borrower, uint marketBorrowIndex, Double memory borrowIndex) internal view returns (uint, uint) {
        TokenFarmState storage state = farmStates[token];
        Double memory borrowerIndex = Double({mantissa: state.borrowerIndex[mToken][borrower]});
        uint _borrowerAccrued = state.accrued[borrower];
        uint borrowerDelta = 0;

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(MToken(mToken).borrowBalanceStored(borrower), Exp({mantissa: marketBorrowIndex}));
            borrowerDelta = mul_(borrowerAmount, deltaIndex);
            _borrowerAccrued = add_(_borrowerAccrued, borrowerDelta);
        }
        return (_borrowerAccrued, borrowerDelta);
    }

    /**
     * @notice Distribute token accrued by a borrower
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @dev To avoid revert: no over/underflow
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute token to
     * @param marketBorrowIndex The market borrow index
     */
    function distributeBorrowerTokenInternal(address token, address mToken, address borrower, uint marketBorrowIndex) internal {
        TokenFarmState storage state = farmStates[token];
        if (isLendingPool == true && state.borrowState[mToken].index > state.borrowerIndex[mToken][borrower] && marketBorrowIndex > 0) {
            Double memory borrowIndex = Double({mantissa: state.borrowState[mToken].index});
            (uint _borrowerAccrued, uint borrowerDelta) = newBorrowerTokenInternal(token, mToken, borrower, marketBorrowIndex, borrowIndex);

            state.borrowerIndex[mToken][borrower] = borrowIndex.mantissa;
            state.accrued[borrower] = _borrowerAccrued;
            emit DistributedBorrowerToken(token, MToken(mToken), borrower, borrowerDelta, borrowIndex.mantissa);
        }
    }

    /**
     * @notice Transfer token to the user
     * @dev Note: If there is not enough token, we do not perform the transfer all.
     * @param token The token to transfer
     * @param user The address of the user to transfer token to
     * @param amount The amount of token to (possibly) transfer
     * @return The amount of token which was NOT transferred to the user
     */
    function grantTokenInternal(address token, address user, uint amount) internal returns (uint) {
        EIP20Interface erc20 = EIP20Interface(token);
        uint tokenRemaining = erc20.balanceOf(address(this));
        if (amount > 0 && amount <= tokenRemaining) {
            erc20.transfer(user, amount);
            return 0;
        }
        return amount;
    }


    /**
     * @notice Claim all the token have been distributed to user
     * @param user The address to claim token for
     * @param token The token address to claim
     */
    function claim(address user, address token) internal {
        uint accrued = farmStates[token].accrued[user];
        uint notClaimed = grantTokenInternal(token, user, accrued);
        farmStates[token].accrued[user] = notClaimed;
        uint claimed = sub_(accrued, notClaimed);
        emit TokenClaimed(token, user, accrued, claimed, notClaimed);
    }

    /**
     * @notice Distribute token accrued to user in the specified markets of specified token
     * @param user The address to distribute token for
     * @param token The token address to distribute
     * @param mTokens The list of markets to distribute token in
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function distribute(address user, address token, MToken[] memory mTokens, bool suppliers, bool borrowers) internal {
        for (uint i = 0; i < mTokens.length; i++) {
            address mToken = address(mTokens[i]);
            
            if (suppliers == true) {
                updateTokenSupplyIndexInternal(token, mToken);
                distributeSupplierTokenInternal(token, mToken, user);
            }

            if (borrowers == true && isLendingPool == true) {
                uint borrowIndex = MToken(mToken).borrowIndex();
                updateTokenBorrowIndexInternal(token, mToken, borrowIndex);
                distributeBorrowerTokenInternal(token, mToken, user, borrowIndex);
            }
        }
    }


    /*** Tokens Farming Called Functions ***/

    /**
     * @notice Accrue token to the market by updating the supply index
     * @param token The token whose supply index to update
     * @param mToken The market whose supply index to update
     */
    function updateTokenSupplyIndex(address token, address mToken) external {
        updateTokenSupplyIndexInternal(token, mToken);
    }

    /**
     * @notice Accrue token to the market by updating the borrow index
     * @param token The token whose borrow index to update
     * @param mToken The market whose borrow index to update
     * @param marketBorrowIndex The market borrow index
     */
    function updateTokenBorrowIndex(address token, address mToken, uint marketBorrowIndex) external {
        updateTokenBorrowIndexInternal(token, mToken, marketBorrowIndex);
    }

    /**
     * @notice Calculate token accrued by a supplier
     * @param token The token in which the supplier is interacting
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute token to
     */
    function distributeSupplierToken(address token, address mToken, address supplier) external {
        distributeSupplierTokenInternal(token, mToken, supplier);
    }

    /**
     * @notice Calculate token accrued by a borrower
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute token to
     * @param marketBorrowIndex The market borrow index
     */
    function distributeBorrowerToken(address token, address mToken, address borrower, uint marketBorrowIndex) external {
        distributeBorrowerTokenInternal(token, mToken, borrower, marketBorrowIndex);
    }

    /**
     * @notice Distribute all the token accrued to user in specified markets of specified token and claim
     * @param token The token to distribute
     * @param mTokens The list of markets to distribute token in
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function dclaim(address token, MToken[] memory mTokens, bool suppliers, bool borrowers) public {
        distribute(msg.sender, token, mTokens, suppliers, borrowers);
        claim(msg.sender, token);
    }

    /**
     * @notice Distribute all the token accrued to user in all markets of specified token and claim
     * @param token The token to distribute
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function dclaim(address token, bool suppliers, bool borrowers) public {
        distribute(msg.sender, token, farmStates[token].tokenMarkets, suppliers, borrowers);
        claim(msg.sender, token);
    }

    /**
     * @notice Distribute all the token accrued to user in all markets of specified tokens and claim
     * @param tokens The list of tokens to distribute and claim
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function dclaim(address[] memory tokens, bool suppliers, bool borrowers) public {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            distribute(msg.sender, token, farmStates[token].tokenMarkets, suppliers, borrowers);
            claim(msg.sender, token);
        }
    }

    /**
     * @notice Distribute all the token accrued to user in all markets of all tokens and claim
     * @param suppliers Whether or not to distribute token earned by supplying
     * @param borrowers Whether or not to distribute token earned by borrowing
     */
    function dclaim(bool suppliers, bool borrowers) public {
        for (uint i = 0; i < allTokens.length; i++) {
            address token = allTokens[i];
            distribute(msg.sender, token, farmStates[token].tokenMarkets, suppliers, borrowers);
            claim(msg.sender, token);
        }
    }

    /**
     * @notice Claim all the token have been distributed to user of specified token
     * @param token The token to claim
     */
    function claim(address token) public {
        claim(msg.sender, token);
    }

    /**
     * @notice Claim all the token have been distributed to user of all tokens
     */
    function claim() public {
        for (uint i = 0; i < allTokens.length; i++) {
            claim(msg.sender, allTokens[i]);
        }
    }


    /**
     * @notice Calculate undistributed token accrued by the user in specified market of specified token
     * @param user The address to calculate token for
     * @param token The token to calculate
     * @param mToken The market to calculate token
     * @param suppliers Whether or not to calculate token earned by supplying
     * @param borrowers Whether or not to calculate token earned by borrowing
     * @return The amount of undistributed token of this user
     */
    function undistributed(address user, address token, address mToken, bool suppliers, bool borrowers) public view returns (uint) {
        uint accrued;
        uint224 _index;
        TokenFarmState storage state = farmStates[token];
        if (suppliers == true) {
            if (state.speeds[mToken] > 0) {
                (_index, ) = newTokenSupplyIndexInternal(token, mToken);
            } else {
                _index = state.supplyState[mToken].index;
            }
            if (uint(_index) > state.supplierIndex[mToken][user]) {
                (, accrued) = newSupplierTokenInternal(token, mToken, user, Double({mantissa: _index}));
            }
        }

        if (borrowers == true && isLendingPool == true) {
            uint marketBorrowIndex = MToken(mToken).borrowIndex();
            if (marketBorrowIndex > 0) {
                if (state.speeds[mToken] > 0) {
                    (_index, ) = newTokenBorrowIndexInternal(token, mToken, marketBorrowIndex);
                } else {
                    _index = state.borrowState[mToken].index;
                }
                if (uint(_index) > state.borrowerIndex[mToken][user]) {
                    (, uint _borrowerDelta) = newBorrowerTokenInternal(token, mToken, user, marketBorrowIndex, Double({mantissa: _index}));
                    accrued = add_(accrued, _borrowerDelta);
                }
            }
        }
        return accrued;
    }

    /**
     * @notice Calculate undistributed tokens accrued by the user in all markets of specified token
     * @param user The address to calculate token for
     * @param token The token to calculate
     * @param suppliers Whether or not to calculate token earned by supplying
     * @param borrowers Whether or not to calculate token earned by borrowing
     * @return The amount of undistributed token of this user in each market
     */
    function undistributed(address user, address token, bool suppliers, bool borrowers) public view returns (uint[] memory) {
        MToken[] memory mTokens = farmStates[token].tokenMarkets;
        uint[] memory accrued = new uint[](mTokens.length);
        for (uint i = 0; i < mTokens.length; i++) {
            accrued[i] = undistributed(user, token, address(mTokens[i]), suppliers, borrowers);
        }
        return accrued;
    }


    /*** Token Distribution Admin ***/

    /**
     * @notice Transfer token to the recipient
     * @dev Note: If there is not enough token, we do not perform the transfer all.
     * @param token The token to transfer
     * @param recipient The address of the recipient to transfer token to
     * @param amount The amount of token to (possibly) transfer
     */
    function _grantToken(address token, address recipient, uint amount) public {
        require(msg.sender == admin, "only admin can grant token");

        uint amountLeft = grantTokenInternal(token, recipient, amount);
        require(amountLeft == 0, "insufficient token for grant");
        emit TokenGranted(token, recipient, amount);
    }

    /**
      * @notice Admin function to add/update erc20 token farming
      * @dev Can only add token or restart this token farm again after endBlock
      * @param token Token to add/update for farming
      * @param start Block heiht to start to farm this token
      * @param end Block heiht to stop farming
      * @return uint 0=success, otherwise a failure
      */
    function _setTokenFarm(EIP20Interface token, uint start, uint end) public returns (uint) {
        require(msg.sender == admin, "only admin can add farm token");
        require(end > start, "end less than start");
        // require(start > 0, "start is 0");

        TokenFarmState storage state = farmStates[address(token)];
        uint oldStartBlock = uint(state.startBlock);
        uint oldEndBlock = uint(state.endBlock);
        uint blockNumber = getBlockNumber();
        require(blockNumber > oldEndBlock, "not first set or this round is not end");
        require(start > blockNumber, "start must largger than this block number");

        uint32 newStart = safe32(start, "start block number exceeds 32 bits");

        // first set this token
        if (oldStartBlock == 0 && oldEndBlock == 0) {
            token.totalSupply(); // sanity check it
            allTokens.push(address(token));
        // restart this token farm
        } else {
            // update all markets state of this token
            for (uint i = 0; i < state.tokenMarkets.length; i++) {
                MToken mToken = state.tokenMarkets[i];

                // update state for non-zero speed market of this token
                uint borrowIndex = mToken.borrowIndex();
                updateTokenSupplyIndexInternal(address(token), address(mToken));
                updateTokenBorrowIndexInternal(address(token), address(mToken), borrowIndex);

                // no matter what we update the block to new start especially for 0 speed token markets
                state.supplyState[address(mToken)].block = newStart;
                state.borrowState[address(mToken)].block = newStart;
            }
        }

        // update startBlock and endBlock
        state.startBlock = newStart;
        state.endBlock = safe32(end, "end block number exceeds 32 bits");
        emit TokenFarmUpdated(token, oldStartBlock, oldEndBlock, start, end);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Set token speed for multi markets
     * @dev Note that token speed could be set to 0 to halt liquidity rewards for a market
     * @param token The token to update speed
     * @param mTokens The markets whose token speed to update
     * @param newSpeeds New token speeds for markets
     */
    function _setTokensSpeed(address token, MToken[] memory mTokens, uint[] memory newSpeeds) public {
        require(msg.sender == admin, "only admin can set tokens speed");

        TokenFarmState storage state = farmStates[token];
        require(state.startBlock > 0, "token not added");
        require(mTokens.length == newSpeeds.length, "param length dismatch");

        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        if (state.startBlock > blockNumber) blockNumber = state.startBlock;
        // if (state.endBlock < blockNumber) blockNumber = state.endBlock;

        for (uint i = 0; i < mTokens.length; i++) {
            MToken mToken = mTokens[i];

            // add this market to tokenMarkets if first set
            if (!state.isTokenMarket[address(mToken)]) {
                require(markets[address(mToken)].isListed == true, "market is not listed");
                state.isTokenMarket[address(mToken)] = true;
                state.tokenMarkets.push(mToken);
                emit NewTokenMarket(token, mToken);

                // set initial index of this market
                state.supplyState[address(mToken)].index = momaInitialIndex;
                state.borrowState[address(mToken)].index = momaInitialIndex;
            } else {
                // Update state for market of this token
                uint borrowIndex = mToken.borrowIndex();
                updateTokenSupplyIndexInternal(token, address(mToken));
                updateTokenBorrowIndexInternal(token, address(mToken), borrowIndex);
            }

            uint oldSpeed = state.speeds[address(mToken)];
            // update speed and block of this market
            state.supplyState[address(mToken)].block = blockNumber;
            state.borrowState[address(mToken)].block = blockNumber;
            if (oldSpeed != newSpeeds[i]) {
                state.speeds[address(mToken)] = newSpeeds[i];
                emit TokenSpeedUpdated(token, mToken, oldSpeed, newSpeeds[i]);
            }
        }
    }


    function getBlockNumber() public view returns (uint) {
        return block.number;
    }
}