// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./Ownable.sol";


contract CarchainCoin is ERC20, Ownable {
    uint256 MAX_CAP = 100000000 * 10 ** 18;

    address PARTNERS_WALLET = 0xF625a26585ff67C983835b692b1b630CE9eE6736;
    address FIRST_SUPPORTERS_REWARDS = 0x501d21CecC4C21A2CAFE94324B889dFB1820f107;
    address FUTURE_TOKEN_SALE = 0x09fADf3FB90Ddf5267c6a450D52b7F730d7F61da;
    address COMPANY_RESERVE = 0x50d2314561A4367964dA9CDCD328ab9F0f2A0e5d;

    address LISANDRO = 0x21AdEbA018e8BA41Cf2d2b822Bfa33a1Fed27018;
    address MAURIZIO = 0x25DC66f98AC3D2f422DDa90F2c05F0a1F55c54d6;
    address PULLUMB = 0x995587183124005F9cFdC03db4F845469f360414;
    address ORNELLA = 0x32c2f004C5cBEbf436a90f5978b8CB12e5B8E711;
    address NOELIA = 0x7089A806fB2Ff48C2CA54Dc652ccAc52c7692a53;
    address ZEESHAN = 0xd239DC840E016Cca481fC36De978537F61073Dfe;
    address NOUMAN = 0x551021fb904082bc86F46C5B45E2D0280eB3864D;
    address PATRICIO = 0x35Ac9d7e528a3f71b173e1a0adc9C0dAa59f0f99;
    address ABU = 0x41001Ee9fcb6E104Fea12707AbB788EcA1271Cf5;
    address LUCIANA = 0x52A9583a543CAbDD06F61a524Fe0EEcfb31F16C8;

    address VEHICLE_TOKENIZATION = 0x4736713C26f7728B3D0740dF1E3E02bE60DC32D6;
    address DOCU_VERIFY = 0x3da29685e4E9621D466C2DE45Cd51236DF6bdf77;

    uint256 TOTAL_VEHICLE_TOKENIZATION = 1000 * 10 ** 18;
    uint256 TOTAL_DOCU_VERIFY = 50 * 10 ** 18;

    mapping (address => Vesting[]) public vestings;

    event TokensReleased(address indexed _to, uint256 _tokensReleased);

    struct Vesting {
        uint256 total;
        uint256 unlockDate;
        bool claimed;
    }

    constructor() ERC20('Carchain Coin', 'CCC')
    {
        uint256 inOneYear = block.timestamp + 365 * 1 days;
        uint256 inTwoYears = inOneYear + 365 * 1 days;
        uint256 inThreeYears = inTwoYears + 365 * 1 days;
        uint256 inFourYears = inThreeYears + 365 * 1 days;

        _mint(PARTNERS_WALLET, 800000 * 10 ** 18);
        _mint(FIRST_SUPPORTERS_REWARDS, 1200000 * 10 ** 18);
        _mint(FUTURE_TOKEN_SALE, 2800000 * 10 ** 18);

        //Company Reserves
        _mint(address(this), 4000000 * 10 ** 18);

        createVesting(COMPANY_RESERVE, 1000000 * 10 ** 18, inOneYear);
        createVesting(COMPANY_RESERVE, 1000000 * 10 ** 18, inTwoYears);
        createVesting(COMPANY_RESERVE, 1000000 * 10 ** 18, inThreeYears);
        createVesting(COMPANY_RESERVE, 1000000 * 10 ** 18, inFourYears);

        //Team Tokens
        _mint(address(this), 1200000 * 10 ** 18);

        createVesting(LISANDRO, 250000 * 10 ** 18, inOneYear);
        createVesting(LISANDRO, 250000 * 10 ** 18, inTwoYears);

        createVesting(MAURIZIO, 75000 * 10 ** 18, inOneYear);
        createVesting(MAURIZIO, 75000 * 10 ** 18, inTwoYears);

        createVesting(PULLUMB, 75000 * 10 ** 18, inOneYear);
        createVesting(PULLUMB, 75000 * 10 ** 18, inTwoYears);

        createVesting(ORNELLA, 75000 * 10 ** 18, inOneYear);
        createVesting(ORNELLA, 75000 * 10 ** 18, inTwoYears);

        createVesting(NOELIA, 75000 * 10 ** 18, inOneYear);
        createVesting(NOELIA, 75000 * 10 ** 18, inTwoYears);

        createVesting(ZEESHAN, 10000 * 10 ** 18, inOneYear);
        createVesting(ZEESHAN, 10000 * 10 ** 18, inTwoYears);

        createVesting(NOUMAN, 10000 * 10 ** 18, inOneYear);
        createVesting(NOUMAN, 10000 * 10 ** 18, inTwoYears);
        
        createVesting(PATRICIO, 10000 * 10 ** 18, inOneYear);
        createVesting(PATRICIO, 10000 * 10 ** 18, inTwoYears);
        
        createVesting(ABU, 10000 * 10 ** 18, inOneYear);
        createVesting(ABU, 10000 * 10 ** 18, inTwoYears);
        
        createVesting(LUCIANA, 10000 * 10 ** 18, inOneYear);
        createVesting(LUCIANA, 10000 * 10 ** 18, inTwoYears);
    }

    function mintForVehicleTokenization() public onlyOwner {
        require(totalSupply() + TOTAL_VEHICLE_TOKENIZATION < MAX_CAP, "Max cap surpased");

        _mint(VEHICLE_TOKENIZATION, TOTAL_VEHICLE_TOKENIZATION);
    }

    function mintForDocuVerify() public onlyOwner {
        require(totalSupply() + TOTAL_DOCU_VERIFY < MAX_CAP, "Max cap surpased");

        _mint(DOCU_VERIFY, TOTAL_DOCU_VERIFY);
    }

    function getTotalToClaimNowByBeneficiary(address _beneficiary) public view returns(uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < vestings[_beneficiary].length; i++) {
            Vesting memory vesting = vestings[_beneficiary][i];
            if (!vesting.claimed && block.timestamp > vesting.unlockDate) {
                total += vesting.total;
            }
        }

        return total;
    }

    function claimVesting() external
    {
        uint256 tokensToClaim = getTotalToClaimNowByBeneficiary(msg.sender);
        require(tokensToClaim > 0, "Nothing to claim");
        
        for (uint256 i = 0; i < vestings[msg.sender].length; i++) {
            Vesting storage vesting = vestings[msg.sender][i];
            if (!vesting.claimed && block.timestamp > vesting.unlockDate) {
                vesting.claimed = true;
            }
        }

        require(transfer(msg.sender, tokensToClaim), "Insufficient balance in contract");
        emit TokensReleased(msg.sender, tokensToClaim);
    }

    function createVesting(address _beneficiary, uint256 _totalTokens, uint256 _unlockDate) internal {
        Vesting memory vesting = Vesting(_totalTokens, _unlockDate, false);
        vestings[_beneficiary].push(vesting);
    }
}