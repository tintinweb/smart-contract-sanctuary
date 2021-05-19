// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

import './IERC20.sol';
import './PreparedPayinV5.sol';

contract ChangeNowMasterPayinV5 {
    address public owner;
    address public successor = address(0);
    uint256 public payins = 0;

    bytes constant payinBytecode = type(PreparedPayinV5).creationCode;
    bytes32 constant payinBytecodeHash = keccak256(payinBytecode);


    constructor() {
        owner = msg.sender;
    }


    /**
     * @notice Checks that caller is owner.
     */
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }


    /**
     * @notice Checks that caller is successor.
     */
    modifier isSuccessor() {
        require(msg.sender == successor, "Caller is not successor");
        _;
    }


    /**
     * @notice Sets new successor (only owner).
     */
    function setSuccessor(address newSuccessor) external isOwner {
        successor = newSuccessor;
    }


    /**
     * @notice Takes ownership (only successor).
     */
    function takeOwnership() external isSuccessor {
        owner = successor;
        successor = address(0);
    }


    /**
     * @notice Converts payin index into subcontract address. Indexing starts from 0.
     *
     * @param {uint256} index - the payin index.
     *
     * @return {address} the corresponding payin subcontract address.
     */
    function payinAddress(uint256 index)
        public
        view
        returns (address)
    {
        return address(uint256(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            bytes32(index),
            payinBytecodeHash
        ))));
    }

    /**
     * @notice Helper function to call payin contract in non-standard way
     * (place selector and following args after token address)
     *
     */
    function _payin_withdrawERC20(address token, address payin, address toAddress, uint256 amount)
        internal
    {
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x80))

            mstore(ptr, shl(224, 0xa9059cbb)) // "transfer(address,uint256)" [ERC20 method]
            mstore(add(ptr, 0x4), toAddress)  // 1st arg
            mstore(add(ptr, 0x24), amount)    // 2nd arg
            mstore(add(ptr, 0x44), token)     // (token address)

            let result := call(gas(), payin, 0, ptr, 0x64, 0, 0)

            if iszero(result) { revert(0, 0) }
        }
    }

    /**
     * @notice Generates next batch of payin subcontracts, up to maxCount
     * (as much as enough gas left), but not less than minCount (be sure you
     * have enough gas to covert the minimum).
     *
     * @param {uint256} minCount - the minimum payins count to generate.
     * @param {uint256} maxCount - the maximum payins count to generate.
     *
     * @return {uint256,uint256} - the tuple (fromIndex, count) of:
     * lowest payin index of generated batch and the batch size.
     *
     * NOTE: the function is not restricted by the isOwner modifier
     *       since there is nothing to protect: the subcontracts are owned
     *       by the factory (this contract) and this one is owned by the
     *       owner, anyone can spend gas to help us to generate the pool.
     */
    function generateNextBatch(uint256 minCount, uint256 maxCount)
        external
        returns (uint256, uint256)
    {
        require(minCount > 0, 'assert: minCount > 0');
        require(maxCount >= minCount, 'assert: maxCount > minCount');

        uint256 fromIndex = payins;
        uint256 calcSinceIndex = fromIndex + minCount;
        uint256 toIndex = fromIndex + maxCount;
        uint256 totalGasUsed = 0;

        uint256 index = fromIndex;

        bytes memory bytecode = payinBytecode;

        while (index < toIndex) {
            if (index >= calcSinceIndex) {
                uint256 avgGas = (totalGasUsed / (index - fromIndex));

                // is there enough gas left (with extra 5k) to generate next?
                if (gasleft() < (avgGas + 5000)) {
                    break;
                }
            }

            uint256 gasBefore = gasleft();

            // create payin subcontract
            bytes32 salt = bytes32(index);
            address payin;
            assembly {
                payin := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }

            totalGasUsed += gasBefore - gasleft();
            index++;
        }

        // save new generated payins count
        payins = index;

        // return (idx, count)
        return (fromIndex, index - fromIndex);
    }

    /**
     * @notice Harvests (withdraw whole balance) ERC20 tokens from batch of payins.
     *
     * @param {address} token - the ERC20 token address to harvest for.
     * @param {uint256} fromIndex - the lowest index of payin of batch to harvest from.
     * @param {uint256} count - the count of payins (batch size) to harvest from.
     * @param {address} toAddress - the destination address to send harvested tokens to.
     *
     * @return {uint256} totalAmount - the total harvested amount.
     */
    function harvestERC20Batch(address token, uint256 fromIndex, uint256 count, address toAddress)
        external
        isOwner
        returns (uint256)
    {
        require(toAddress != address(this), 'toAddress is this');
        require(toAddress != address(0), 'toAddress is zero');

        uint256 toIndex = fromIndex + count;
        uint256 totalAmount = 0;

        require(toIndex <= payins, 'not enough payins');

        // send from payins (batch)
        while (fromIndex < toIndex) {
            address payin = payinAddress(fromIndex);
            uint256 amount = IERC20(token).balanceOf(payin);

            if (amount > 0) {
                _payin_withdrawERC20(token, payin, toAddress, amount);
                totalAmount += amount;
            }

            fromIndex++;
        }

        return totalAmount;
    }


    /**
     * @notice Harvests (withdraw whole balance) ERC20 tokens from batch of payins.
     *
     * @param {address} token - the ERC20 token address to harvest for.
     * @param {address[]} batch - the batch of addresses to harvest from.
     * @param {address} toAddress - the destination address to send harvested tokens to.
     *
     * @return {uint256} totalAmount - the total harvested amount.
     */
    function harvestERC20BatchFor(address token, address[] calldata batch, address toAddress)
    external isOwner returns (uint256)
    {
        require(toAddress != address(this), 'toAddress is this');
        require(toAddress != address(0), 'toAddress is zero');

        uint256 totalAmount = 0;

        // send from given payins (batch)
        for (uint256 i = 0; i < batch.length; i++) {
            address payin = batch[i];
            uint256 amount = IERC20(token).balanceOf(payin);

            if (amount > 0) {
                _payin_withdrawERC20(token, payin, toAddress, amount);
                totalAmount += amount;
            }
        }

        return totalAmount;
    }
}