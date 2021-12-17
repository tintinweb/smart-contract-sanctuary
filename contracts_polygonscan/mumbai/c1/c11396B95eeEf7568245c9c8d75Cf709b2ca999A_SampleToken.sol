import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract SampleToken is ERC20, Ownable, ERC20Burnable{
    constructor() ERC20("Sample Token", "SMT"){}
    function decimals() public view  override returns (uint8) {
        return 6;
    }

    function mint(uint256 amount) external onlyOwner{
        _mint(_msgSender(), amount);
    }

    function mint(address to, uint256 amount) external onlyOwner{
        _mint(to, amount);
    }
}