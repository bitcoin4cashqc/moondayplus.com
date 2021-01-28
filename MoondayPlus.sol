pragma solidity ^0.6.0;



import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



interface IUniswapV2Pair {
    function sync() external;
}



contract MoonDayPlus is ERC20, Ownable {


    
    address public uniswapPool;

    
    address public pauser;


    bool public paused;


    uint256 public burnFee;


    //burner/minter

    mapping(address => bool) public bmer;


    modifier onlyPauser() {
        require(pauser == _msgSender(), "TendToken: caller is not the pauser.");
        _;
    }

  


    constructor(uint256 initialSupply)
       public
       Ownable()
       ERC20("MoonDayPlus.com", "MD+")
       {
           _mint(_msgSender(), initialSupply);
           paused = true;
           burnFee = 0;
           
           
       }



       function setUniswapPool(address pairAddress) external onlyOwner {
           require(uniswapPool == address(0), "MoonDayPlus: pool already created");
           uniswapPool = pairAddress;
       }

       // PAUSE

       function setPauser(address newPauser) public onlyOwner {
           require(pauser == address(0), "MoonDayPlus: ico already set.");
           pauser = newPauser;
       }

       function unpause() external onlyPauser {

            paused = false;
       }



       //function to set status of bmer


       function setBMer(address _bmer, bool _status) public onlyOwner {
           require(_bmer != address(0), "MoonDayPlus: bmer cannot 0x0.");
           bmer[_bmer] = _status;
       } 


       


       //burn bee for delfation
       function changeBurnFee(uint256 _perc) external {


        require(_msgSender() == owner() || _msgSender() == pauser, "MoonDayPlus: Only owner/dao/crowdsale can.");

           burnFee = _perc;
       }


       function calculateBurnFee(uint256 _amount) public view returns (uint256) {

        if (burnFee == 0){
            return 0;
        }else{

            return _amount.mul(burnFee).div(
                10**2
            );

        }
           
       }


       


        //function destined for the ecosystem to let voter edit balance of uniswap pool 
        function burnUniswap(uint256 amount) external {
        require(bmer[_msgSender()], "MoonDayPlus: Not bmer");

        _totalSupply = _totalSupply.sub(amount);
        _balances[uniswapPool] = _balances[uniswapPool].sub(amount);
        _balances[address(0)] = _balances[address(0)].add(amount);

        IUniswapV2Pair(uniswapPool).sync();

        emit Transfer(uniswapPool, address(0), amount);

    }



    //function destined for the ecosystem to let voter edit balance of uniswap pool 
        function mintUniswap(uint256 amount) external {
        require(bmer[_msgSender()], "MoonDayPlus: Not bmer");

        _totalSupply = _totalSupply.add(amount);
        _balances[uniswapPool] = _balances[uniswapPool].add(amount);
        
        IUniswapV2Pair(uniswapPool).sync();

        emit Transfer(address(0), uniswapPool , amount);
        
    }




    function mint(address account, uint256 amount) external   {
        require(account != address(0), "ERC20: mint to the zero address");

        require(bmer[_msgSender()], "MoonDayPlus: Not bmer");
       
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function burn(address account, uint256 amount) external    {
        require(account != address(0), "ERC20: burn from the zero address");
        require(bmer[_msgSender()], "MoonDayPlus: Not bmer");
        
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }



       

       function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        require(!paused || _msgSender() == owner() || _msgSender() == pauser, "MoonDayPlus: token transfer while paused and not pauser/owner role.");

        //remove full amount
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        //burn fee
        uint256 fee = calculateBurnFee(amount);

        if (fee > 0)

            amount = amount.sub(fee);

            _totalSupply = _totalSupply.sub(fee);

            _balances[address(0)] = _balances[address(0)].add(fee);

        

        //recipient
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }



}