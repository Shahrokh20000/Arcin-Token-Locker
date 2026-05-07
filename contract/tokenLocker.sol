// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);

}



contract tokenLocker{
    bytes4 private constant transferSELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant transferFromSELECTOR = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));

    error insufficientBalance();
    error notOwnerAddress();
    address immutable ContractOwner = msg.sender;

modifier onlyOwner(){
    if(msg.sender != ContractOwner){
        revert notOwnerAddress();
    }
    _;
}

struct userPortfo{
    address token;
    uint256 balance;
}
//user --->>> token --->>> index in array 
mapping(address => mapping ( address => uint256 )) private pointPortfoIndex;
mapping(address => mapping (address => bool)) private isDeposited;
//counter for loops in front-end
//user --->>> counter
mapping(address => uint256) private indexCounter;

mapping(address => userPortfo[]) private dappPortfo;

//for native token the address is zero and we trust it because only dapp has access to this function
function updateDappPortfo(address user, address _token, uint256 _amount,bool isAdd) private {
    if(isAdd){
        if(isDeposited[user][_token]){
    dappPortfo[user][pointPortfoIndex[user][_token]].balance += _amount;
    }
    else{
        dappPortfo[user].push(userPortfo(_token,_amount));
         pointPortfoIndex[user][_token]= dappPortfo[user].length-1;
         indexCounter[user]++;
         isDeposited[user][_token]=true;
    }

    }
    else{
    dappPortfo[user][pointPortfoIndex[user][_token]].balance -= _amount;
    }
}
//---------------------loading portfolio----------------------


//-------------counter for loops in frontend-------------
function userTokensCount(address user) public view returns(uint256){
    return indexCounter[user];
}

function userTokens(address user , uint256 index) public view returns(address){
    return dappPortfo[user][index].token;
}
function userBalanceOfDepositedToken(address user, address _token) public view returns(uint256){
    return dappPortfo[user][pointPortfoIndex[user][_token]].balance;
}
//------------safe transfer from function------------
error safeTransferFromFailed();
function safeTransferFrom(address token ,address from, address to , uint256 amount) private{
    (bool success,bytes memory data) = token.call(abi.encodeWithSelector(transferFromSELECTOR,from,to,amount));
    if(!(success && (data.length == 0 || abi.decode(data,(bool))))){
        revert safeTransferFromFailed();
    }
    }
 //-------------safe transfer function----------
    error safeTransferFailed();
function safeTransfer(address token ,address to , uint256 amount) private{
    (bool success,bytes memory data) = token.call(abi.encodeWithSelector(transferSELECTOR,to,amount));
    if(!(success && (data.length == 0 || abi.decode(data,(bool))))){
        revert safeTransferFailed();
    }
}

//----------------deposite native token-----------------
    
    mapping(address => uint256) private balances;

    event spent(address spender , uint256 sent , uint256 balanceOf);
    function getEther() public payable{
        if (msg.value <= 0){
            revert insufficientBalance();
        }
        else{
            balances[msg.sender] += msg.value;
        emit spent(msg.sender , msg.value ,balances[msg.sender]);
        }

        updateDappPortfo(msg.sender, address(0), msg.value,true);
        
    } 

//----------------deposite erc20token------------------


    //------contract---->------account-->--balance--------
    mapping(address => mapping(address => uint256)) private erc20Balances;

    //list of tokens deposited to contract
    address[] private  erc20tokenAddress;
    //counter for front-end loop
    uint256 private counter=0;
    mapping(address=>bool) private isadded;
    event dopositeERC20(address spender , uint256 sent , uint256 balanceOf);
    error invalidAmount();
    function deposit(uint256 value , address contractAddress) public {
        if(value <= 0){
            revert invalidAmount();
        }
        //fee on transfer protection
        uint256 balanceBefore = IERC20(contractAddress).balanceOf(address(this));
        safeTransferFrom(contractAddress, msg.sender, address(this), value);
        uint256 actualReceived = IERC20(contractAddress).balanceOf(address(this)) - balanceBefore;
        erc20Balances[contractAddress][msg.sender] += actualReceived;
        emit dopositeERC20(msg.sender, actualReceived, erc20Balances[contractAddress][msg.sender]);
        if(!isadded[contractAddress]){
            erc20tokenAddress.push(contractAddress);
            isadded[contractAddress] = true;
    }
    updateDappPortfo(msg.sender, contractAddress, actualReceived, true);
}

    //------------------withdraw native-----------------------
    error insufficientDappBalance();
    error etherTransferFailed();
    function withdrawEther(uint256 amountToWithdraw) public {
        if(amountToWithdraw > balances[msg.sender]){
            revert insufficientDappBalance();
        }
        else{
            balances[msg.sender] -= amountToWithdraw;
            (bool success,) = (msg.sender).call{value:amountToWithdraw}("");
            if (success){
                emit spent(msg.sender,amountToWithdraw, balances[msg.sender]);
            }
            else {
                revert etherTransferFailed();
            }
            
        }
        updateDappPortfo(msg.sender, address(0), amountToWithdraw,false);
    }


    //-------------- wathdraw erc20 tokens ----------------


    function withdrawERC20(uint256 amountToWithdraw , address contractAddress) public {
        if(erc20Balances[contractAddress][msg.sender] < amountToWithdraw){
            revert insufficientDappBalance();
        }
        else{
            erc20Balances[contractAddress][msg.sender] -= amountToWithdraw; ///re-entrency shield
            safeTransfer(contractAddress,msg.sender,amountToWithdraw);
            emit spent(msg.sender,amountToWithdraw, erc20Balances[contractAddress][msg.sender]);
        }
        updateDappPortfo(msg.sender, contractAddress, amountToWithdraw,false);
    }
    
    ///for emergency withdrawals
    error emergencyEthWithdrawFailed();
    error invalidIndex();
    function emergencyWithdraw(uint256 index) public onlyOwner returns(uint256 _counter){
        if(counter==0){
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            if(!success){
                revert emergencyEthWithdrawFailed();
            }
            counter = erc20tokenAddress.length;
            return counter;
        }
        else{
            if(erc20tokenAddress.length < index +1){
                revert invalidIndex();
            }
            {
                address contractAddress = erc20tokenAddress[index];
            uint256 balance = IERC20(contractAddress).balanceOf(address(this));
            if(balance>0){
                uint256 amountToWithdraw = balance;
                safeTransfer(contractAddress,msg.sender, amountToWithdraw);
            }
            }
            counter--;
        }
    }
}
