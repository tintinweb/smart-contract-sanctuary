// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface camToken {
    function claimAaveRewards() external;
    function harvestMaticIntoToken() external;
}

contract AutoCompounder {

    camToken aave = camToken(0xeA4040B21cb68afb94889cB60834b13427CFc4EB);
    camToken wmatic = camToken(0x7068Ea5255cb05931EFa8026Bd04b18F3DeB8b0B);
    camToken weth = camToken(0x0470CD31C8FcC42671465880BA81D631F0B76C1D);
    camToken wbtc = camToken(0xBa6273A78a23169e01317bd0f6338547F869E8Df);
    camToken dai = camToken(0xE6C23289Ba5A9F0Ef31b8EB36241D5c800889b7b);
    camToken usdc = camToken(0x22965e296d9a0Cd0E917d6D70EF2573009F8a1bB);
    camToken usdt = camToken(0xB3911259f435b28EC072E4Ff6fF5A2C604fea0Fb);

    constructor () {

    }

    uint256 public lastExecuted;

    modifier onlyGelato() {
        require(msg.sender == address(0x7598e84B2E114AB62CAB288CE5f7d5f6bad35BbA), "Gelatofied: Only gelato");
        _;
    }

    /*

        Try catch flow
        
        cost: 0.1 Matic per task

    */

    function lastExec() internal view returns (bool) {
        return ((block.timestamp - lastExecuted) > 86400);
    }

    function autoCompound() external onlyGelato() {
        require(
            lastExec(),
            "autoCompound: Time not elapsed"
        );

        try aave.claimAaveRewards() {
        } catch {
        }

        try aave.harvestMaticIntoToken() {
        } catch {
        }
        
        try wmatic.claimAaveRewards() {
        } catch {
        }

        try wmatic.harvestMaticIntoToken() {
        } catch {
        }

        
        try weth.claimAaveRewards() {
        } catch {
        }

        try weth.harvestMaticIntoToken() {
        } catch {
        }

        
        try wbtc.claimAaveRewards() {
        } catch {
        }

        try wbtc.harvestMaticIntoToken() {
        } catch {
        }

        
        try dai.claimAaveRewards() {
        } catch {
        }

        try dai.harvestMaticIntoToken() {
        } catch {
        }

        
        try usdc.claimAaveRewards() {
        } catch {
        }

        try usdc.harvestMaticIntoToken() {
        } catch {
        }
        

        try usdt.claimAaveRewards() {
        } catch {
        }

        try usdt.harvestMaticIntoToken() {
        } catch {
        }

        lastExecuted = block.timestamp;
    }

    function resolver() external returns (bool) {
        return lastExec();
    }

}