
pragma solidity ^0.6.0;


import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/GSN/Context.sol";

import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface Pauseable {
    function unpause() external;
    function changeBurnFee(uint256 _perc) external;
}

/**
 * @title MoonPlusCrowdsale
 * @dev Crowdsale contract for $MOON. 
 *      Contributions limited to whitelisted addresses during the first hour (1.5 ETH for Round 1, 3 ETH for Round 2), fcfs afterwards.
 *      1 ETH = 20000 MOON (during the entire sale)
 *      Hardcap = 150 ETH
 *      Once hardcap is reached, all liquidity is added to Uniswap and locked automatically, 0% risk of rug pull.
 *
 * @author soulbar@protonmail.com
 */
contract MoondayPlusCrowdsale is Ownable {
    using SafeMath for uint256;
    

    // Caps
    uint256 public constant ROUND_1_CAP = 7.875 ether;
    


    uint256 public constant MAX_CONTRIBUTION_WHITE = 0.5 ether;
    

    uint256 public constant MIN_CONTRIBUTION = 0.1 ether;
    
    uint256 public constant HARDCAP = 57.92180625 ether;

    // Start time 5pm UTC 26 jan 2021
    //uint256 public  CROWDSALE_START_TIME = 1611691200;
    // Start time 5pm UTC 26 jan 2021
    uint256 public  CROWDSALE_START_TIME = block.timestamp;


    // End time
    uint256 public CROWDSALE_END_TIME = CROWDSALE_START_TIME + 48 hours;

    // 1 ETH = 19.84 MOON

    uint256 public constant MOON_PER_ETH = 21.365010522 ether;

    uint256 public constant MOON_PER_ETH_WHITE = 28.571428571 ether;

    // Round 1 whitelist
    mapping(address => bool) public whitelistCapsRound1;


    // Contributions state
    mapping(address => uint256) public contributions;

    uint256 public weiRaised;

    bool public liquidityLocked = false;

    IERC20 public moonToken;

    IUniswapV2Router02 internal uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    

    event TokenPurchase(address indexed beneficiary, uint256 weiAmount, uint256 tokenAmount);

    constructor(IERC20 _moonToken) Ownable() public {
        moonToken = _moonToken;
    }

    receive() payable external {
        // Prevent owner from buying tokens, but allow them to add pre-sale ETH to the contract for Uniswap liquidity
        if (owner() != msg.sender) {
            _buyTokens(msg.sender);
        }
    }

    function _buyTokens(address beneficiary) internal {
        
        uint256 weiAmount;
        
         if(isWithinCappedSaleWindow()){
            uint256 weiToVipcap = ROUND_1_CAP.sub(weiRaised);
            weiAmount = weiToVipcap < msg.value ? weiToVipcap : msg.value;
        
        }else{
            uint256 weiToHardcap = HARDCAP.sub(weiRaised);
            weiAmount = weiToHardcap < msg.value ? weiToHardcap : msg.value;
        }
        

        _buyTokens(beneficiary, weiAmount);

        uint256 refund = msg.value.sub(weiAmount);
        if (refund > 0) {
            payable(beneficiary).transfer(refund);
        }
    }

    function _buyTokens(address beneficiary, uint256 weiAmount) internal {

        if(isWithinCappedSaleWindow()){
            require(whitelistCapsRound1[msg.sender],"not whitelisted");
            require(weiRaised <= ROUND_1_CAP, "VIP REACHED");
            
            require(contributions[beneficiary].add(weiAmount) <= MAX_CONTRIBUTION_WHITE , "MoonPlusCrowdsale: bigger than max contribution whitesale.");
            
        }
        
        require(weiAmount >= MIN_CONTRIBUTION, "MoonPlusCrowdsale: smaller than min contribution.");
            


        _validatePurchase(beneficiary);

        // Update internal state
        weiRaised = weiRaised.add(weiAmount);
        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);

        // Transfer tokens
        uint256 tokenAmount = _getTokenAmount(weiAmount);
        moonToken.transfer(beneficiary, tokenAmount);

        emit TokenPurchase(beneficiary, weiAmount, tokenAmount);
    }

    function _validatePurchase(address beneficiary) internal view {
        require(beneficiary != address(0), "MoonPlusCrowdsale: beneficiary is the zero address");
        require(isOpen(), "MoonPlusCrowdsale: sale did not start yet.");
        require(!hasEnded(), "MoonPlusCrowdsale: sale is over.");

       
        this; // solidity being solidity doing solidity things, few understand this.
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        if(whitelistCapsRound1[msg.sender] && isWithinCappedSaleWindow()){
            
            return weiAmount.mul(MOON_PER_ETH_WHITE.div(1e18)); 
            
        }else{
            
            return weiAmount.mul(MOON_PER_ETH.div(1e18)); 
            
        }
            
        
        
    }

    function isOpen() public view returns (bool) {
        return now >= CROWDSALE_START_TIME;
    }

    function isWithinCappedSaleWindow() public view returns (bool) {
        return now >= CROWDSALE_START_TIME && now <= (CROWDSALE_START_TIME + 24 hours) && weiRaised < ROUND_1_CAP;
    }

    function hasEnded() public view returns (bool) {
        return now >= CROWDSALE_END_TIME || weiRaised >= HARDCAP;
    }

    // Whitelist

    function setWhitelist1(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelistCapsRound1[accounts[i]] = true;
        }
    }



    // Uniswap

    function addAndLockLiquidity() external {
        require(hasEnded(), "MoonPlusCrowdsale: can only send liquidity once hardcap is reached");

        uint256 amountEthForUniswap = address(this).balance;
        uint256 amountTokensForUniswap = moonToken.balanceOf(address(this));

        // Unpause transfers forever
        Pauseable(address(moonToken)).unpause();
        // Send the entire balance and all tokens in the contract to Uniswap LP
        moonToken.approve(address(uniswapRouter), amountTokensForUniswap);

        

        uniswapRouter.addLiquidityETH
        { value: amountEthForUniswap }
        (
            address(moonToken),
            amountTokensForUniswap,
            amountTokensForUniswap,
            amountEthForUniswap,
            address(0), // burn address
            now
        );


        Pauseable(address(moonToken)).changeBurnFee(1);


        liquidityLocked = true;
    }
}
