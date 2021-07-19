//SourceUnit: ContractReader.sol

pragma solidity >=0.4.23 <=0.6.0;

interface MixerTokenDispenser {
    function currentEpoch() external view returns (uint256);
    function genesisBlock() external view returns (uint256);
    function EPOCH_BLOCKS() external view returns (uint256);
    function BIG_EPOCHS() external view returns (uint256);
    function TOTAL_BIG_EPOCHS() external view returns (uint256);
    function getCurrentDispenseAmount() external view returns (uint256);

    function amountForClaimant(address targetAddr) external view returns (uint256);
    function estimatedPendingAmountForClaimant(address targetAddr) external view returns (uint256);
    function lastEpochForClaimer(address targetAddr) external view returns (uint256);
    function lastAmountForClaimer(address targetAddr) external view returns (uint256);
}

interface MixerCoinStaker {
    function dividend(address stakerAddr, address token) external view returns (uint256);
}

interface Tornado {
    function netAmount() external view returns (uint256);
    function obsfucationLevel() external view returns (uint256);

    function zeros(uint256 index) external view returns (bytes32);
    function filledSubtrees(uint256 index) external view returns (bytes32);
}

interface TornadoERC20 {
    function netAmount() external view returns (uint256);
    function obsfucationLevel() external view returns (uint256);
    function token() external view returns (address);
}

interface ERC20 {
    function balanceOf(address targetAddr) external view returns (uint256);
}


contract ContractReader {
    function readDispenserData(MixerTokenDispenser addr) public view returns (uint256[6] memory) {
        uint256[6] memory r;

        r[0] = addr.currentEpoch();
        r[1] = addr.genesisBlock();
        r[2] = addr.EPOCH_BLOCKS();
        r[3] = addr.BIG_EPOCHS();
        r[4] = addr.TOTAL_BIG_EPOCHS();
        r[5] = addr.getCurrentDispenseAmount();

        return r;
    }

    function readDispenserDataForUser(MixerTokenDispenser addr, address targetAddr) public view returns (uint256[4] memory) {
        uint256[4] memory r;

        r[0] = addr.amountForClaimant(targetAddr);
        r[1] = addr.estimatedPendingAmountForClaimant(targetAddr);
        r[2] = addr.lastEpochForClaimer(targetAddr);
        r[3] = addr.lastAmountForClaimer(targetAddr);

        return r;
    }

    function readDividends(MixerCoinStaker addr, address stakerAddr, address[] memory tokens) public view returns (uint256[] memory) {
        uint256[] memory r = new uint256[](tokens.length);
        uint i;

        for (i = 0; i < tokens.length; i++) {
            r[i] = addr.dividend(stakerAddr, tokens[i]);
        }

        return r;
    }

    function readTornadoETH(Tornado addr) public view returns (uint256[3] memory) {
        uint256[3] memory r;

        r[0] = addr.netAmount();
        r[1] = addr.obsfucationLevel();
        r[2] = address(addr).balance;
        
        return r;
    }

    function readTornadoERC20(TornadoERC20 addr) public view returns (uint256[3] memory) {
        uint256[3] memory r;
        ERC20 token;

        r[0] = addr.netAmount();
        r[1] = addr.obsfucationLevel();
        token = ERC20(addr.token());
        r[2] = token.balanceOf(address(addr));

        return r;
    }

    function readTreeData(Tornado addr) public view returns(bytes32[32] memory, bytes32[32] memory) {
        bytes32[32] memory zeros;
        bytes32[32] memory filledSubtrees;

        uint256 i;
        for(i = 0; i < 32; i++) {
            zeros[i] = addr.zeros(i);
            filledSubtrees[i] = addr.filledSubtrees(i);
        }

        return (zeros, filledSubtrees);
    }
}