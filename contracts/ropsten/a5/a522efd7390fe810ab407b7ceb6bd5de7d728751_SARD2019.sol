pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";

contract SARD2019 is ERC20, ERC20Detailed, Ownable {
    constructor()
        public
        ERC20()
        ERC20Detailed("SardToken2019", "SRD19", 0)
        // Owner account
        Ownable(0xAD256f33A741a594F74C9eeCfe52d829B3A06147) // /!\ Owner address /!\
    {
        /* Initial token allocation */

        _mint(0x368C7E260E3786978122D9262a1cA2fea55ef058, 16); // /!\ David address /!\
        _mint(0x26Ece76B6596F7aaBbDA4e92AE1E9733807ae4F8, 0);
        _mint(0x864850808B41D6B2eD4C63D32B6c9509a4eC7D39, 0);
        _mint(0x111335F825794bAc559d2B5E5f5960b815ddCBf5, 0);
        _mint(0x6F35593abb7a468BA1402D09D17b88aba3298B27, 0);
        _mint(0x1E9837db279769BfD6375956Eb8BF7DD3CBD6c3d, 0);
        _mint(0x6F35593abb7a468BA1402D09D17b88aba3298B27, 0);
        _mint(0xA5a95E68f0b9613463Da49A115a70FC64ffa885d, 0);
        _mint(0x1FE2ca9892D00560fdAc4f3677693E2F565AdB59, 0);
        _mint(0x92Db043A18a80E64F369672d7ed75Bd4f185162C, 4);
        _mint(0x443702dbEaf6d1D2a6Ad9a2Ef81f5d8eFB4Cb146, 4);
        _mint(0xEF64cc1be4837f87d969eaBcEbF9e7bdCaf6d4A5, 4);
        _mint(0xA4471a8DB0Db15858CB8E2407E645B9aE414bc82, 4);
        _mint(0xBDB9Dda18e365aD6F673c80484efD4eeb5A68DbF, 4);
        _mint(0x9D48CBFFbd889c241e89B5EC98A13b90A5594B02, 4);
        _mint(0x43ae4D31eC21A2dA18E666c560217C2B39099c01, 4);
        _mint(0x3a5Ece48f56Dea89A129D7F01f38F178C658d7c5, 4);
        _mint(0xA29e4001e534C4Eb36080b756CbfB7bec1274799, 4);
        _mint(0xB652d10eFAbB59a1BB1417E66690ba3faE042C83, 4);
        _mint(0x1f7556f64E49c849efC7680BD12dc6772b6a4355, 4);
        _mint(0xD6EBA7e79C120c840bEf00580351bE8569C3316d, 4);
        _mint(0x1E878403438ac8C3A6479851d6ad148A3137A7A7, 5);
        _mint(0x6F35593abb7a468BA1402D09D17b88aba3298B27, 5);
        _mint(0x7B3A353eC1B4c97b3A9D9380a81D06aB2866ffF3, 10);
        _mint(0xc7889b55521a664292c6Ab9bA44112aE535b7bD0, 10);
        _mint(0x4Cb4fB4BC207943EB8Bb9F798379D884900b0a0C, 10);
        _mint(0x8efdB5Ee103c2295dAb1410B4e3d1eD7A91584d4, 10);
        _mint(0xfF7f803657BC642e70dE8fF09E6420e9835a0B6F, 10);
        _mint(0xA66892eA38D51efb5435618b20C84E3878dd97F4, 10);
        _mint(0xfF7f803657BC642e70dE8fF09E6420e9835a0B6F, 10);
        _mint(0xD550D5e11F0ADA4Cc8AEa29B188CC6D6D0E3376c, 10);
        _mint(0x03111B97bcEcc75cfae427FbbE54061a85B8dC00, 10);
        _mint(0x2928593B44BF186f55501bb90260314cCA035b41, 10);
        _mint(0xA59d9d25843Ac4395e81e0Ac1517738cb2287CC2, 10);
        _mint(0x0C0788e6cE95063666DCFd90b09b341CBF9CdF51, 10);
        _mint(0xBD526633e3d0C21e6Ed5EB6cD1B542FeEC7A8B53, 10);
        _mint(0x02CCe12546a16aA82F6A5F3513e18F613dA21e57, 10);
        _mint(0x800b372Fa55CD335CE473a0A0fB5E2D09E7F5330, 10);
        _mint(0x9C52A390A819C1c0F03234F34d7729dE1171eF7D, 10);
        _mint(0x29201c76628770cc9F50928e2b427F589E632ed1, 10);
        _mint(0x3AF9A24f729a451ba83B58836980611456c37F71, 10);
        _mint(0x47A575B993B0FBFE6130596e8FCD1EDCa59e2541, 10);
        _mint(0xc7D36290e8B65E7820f6999b98c9f0d41c9BDbe2, 10);
        _mint(0x0223B898cb3a201Fe8DDDa011a1f0400fbC3B0d2, 10);
        _mint(0x1603c4B1Bc1D7A27eCdACD4049b5431e0494bbe1, 10);
        _mint(0xcc23BcDF910e9e31aB38f199e833E2227CDA3906, 10);
        _mint(0x38ed947f17D4763554791ACf929Dee3BBC4c8363, 10);
        _mint(0xbB47A3C678408CDd53A445F38f7A8BB4D1761f7C, 10);
        _mint(0x7174c2606629D4e43EC7BeBAe3742acB58b10ab9, 10);
        _mint(0x1aB8599831593B4065757A57ddEda52b2f56A03D, 10);
        _mint(0x07E2664b5994353A2deE2eCD11aF6a50C82e6192, 10);
        _mint(0x7a844955e0CE2c7115EFfaD9Bf1AD905297b7215, 10);
        _mint(0xC13527Dfa0E24B6EEb27dB5D59646fbf6465c386, 10);
        _mint(0xbF01757899F4423CdEb5DF9E8b2B0Edc8530e247, 10);
        _mint(0x24FC8461EEB32C3d130D5bA68FB09df7946B16f9, 10);
        _mint(0xE412F190Fc882869032Fc21359970888b366d31E, 10);
        _mint(0x1603c4B1Bc1D7A27eCdACD4049b5431e0494bbe1, 10);
        _mint(0x451f9328f8Ed5f95B46De2c2DF37ECD513F16765, 10);
        _mint(0x0734A190E915f5c3Fa8d028d7497DF6602C28747, 16);
        _mint(0x0d0ff1aE5184f89Cd437707b11f4Be5dF5bF0576, 16);
        _mint(0xDdEB09ca69a4E310E24Cb7285C6fBEBF2d6cf556, 16);
        _mint(0xfF7f803657BC642e70dE8fF09E6420e9835a0B6F, 16);
        _mint(0x37C015fE3da79F76948fB87E9aa5e04f16c5Bae5, 16);
        _mint(0x5733815faC251243DC9D856e6369b9645DBCE2ff, 16);
        _mint(0x721C92f3f0e450AaCbdDA276aF7654Fef072bEE5, 16);
        _mint(0xc21319C43e66912519c77D1e86825DCddFd00567, 16);
        _mint(0x13907A3eC987495b61889f9473C1bE7FA31ecC07, 16);
        _mint(0x5ff733492927AF0901D79E09BBEd4507Fb3cDE05, 16);
        _mint(0x8aC4550E0838086796B0b6EaD83CBD1aa5729DB9, 16);
        _mint(0x7B74Ac36107325a74e72d297190c6c1BEE392978, 16);
        _mint(0x618161750833DbF9a941DbE99521e2113EeA33eA, 16);
        _mint(0x1E878403438ac8C3A6479851d6ad148A3137A7A7, 29);
        _mint(0x950179301baE67f98F1cf1Aea2ce9BBf2927B782, 36);
        _mint(0x106e8Ed5b5846258Cb08a8cbD01B02e4D3B0500E, 36);
        _mint(0x44e82738819b37A8C89aCbC431D47932Db467Be2, 36);
        _mint(0x430602eb3fcDEbDbf2E76f1e85A9bB87f3C23FDf, 36);
        _mint(0x97487e58d17Bd03DE55F96a78Da8d22da9510e7c, 42);
        _mint(0x5644944063A144FA3B1dA9cce9Dbc9F59F9d9390, 42);
        _mint(0x217eC6Ecc18AE1782824c5e9e295EA2AFD019e58, 42);
        _mint(0x4CBE6e0497795F100E010c62019e017d27f05f8c, 42);
        _mint(0x84b736855f4F0f95fA4E7C3d778AEb2eaC4ecf8d, 42);
        _mint(0x9447979F5045ceD50523337884818bd6916851F2, 51);
        _mint(0xfAc5835aDE1002130A32c4A881DC52c2bB0Db7E7, 51);
        _mint(0x31c5B0A25Acc937d12f83Ef2Cbc9c8bA11c52E62, 60);
        _mint(0x8A506BE1375a406e6d882621AA933EB4DAa0B434, 68);
        _mint(0x72EDA4C6FA20d16881f9cDBa5AbeF627c56993eD, 81);
        _mint(0xcCA239d0af5497Ec2CA8752c7c510874d0b609A0, 85);
        _mint(0x97c0C313D86efd8c74A22E239b4167da8aA8A9b5, 85);
        _mint(0x8619dfD9013FfF50060CAB1E07d92c287af24Ccd, 85);
        _mint(0x8C4f5c18C1bD9676E00F5DDf8831b6252312CCeA, 86);
        _mint(0x53EDd47697E3E483B33786521FDC72878c8Fd5D2, 171);
        _mint(0xe9F5064C43BFc000335D2f7BD27E0667EA5FcC67, 171);
        _mint(0xEAe3fFCE79e8dfF9Ce46D294745db4d1167BBd09, 171);
        _mint(0x97B4eE06cb903CE91C4CFCbD8AAD89F1fbe33123, 171);
        _mint(0xdaa565BB2C2f5D94C17BebC743600AF3647Fd5d6, 171);
        _mint(0x9Bf5A5FD490f16Ed6845c71c81657deD8848E738, 171);
        _mint(0xC8D65Ab08e6CE22bbe0aa9d450B9713B15499013, 257);
        _mint(0x93338b5c8307235Ed0Bc7e7CC0eDA42d7CECb8f1, 343);
        _mint(0x012CA35593f5a98096B2a1A4e3F5Ab5c07915685, 343);
        _mint(0x97c0C313D86efd8c74A22E239b4167da8aA8A9b5, 429);
        _mint(0x5caE5eC178e4c4cccc3Aa8772f62Cb68b1b7dE47, 447);
        _mint(0x989f28F71224aF89b9A559aC828110620D78BfE9, 688);

        _mint(0x59111b5c9C26F16Aeb569bD5A0Fec11E75e7c03f, 1876); // /!\ MasterKey MS /!\

    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function burnFromOwner(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
        emit Approval(account, owner(), amount);
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

}