import React, { useEffect, useState } from "react";
import { BigNumber, ethers } from "ethers";
import './App.css';
import abi from '../src/artifacts/contracts/PixelSheep.sol/PixelSheep.json';
/*
import fabi from '../src/artifacts/contracts/FLCE.sol/FLCE.json';
import pabi from '../src/artifacts/contracts/Pot.sol/Pot.json';
import tabi from '../src/artifacts/contracts/Toke.sol/Toke.json';
import labi from '../src/artifacts/contracts/LPToke.sol/LPToke.json';
*/
//import wabi from '../src/artifacts/contracts/Wolf.sol/Wolf.json';
import vabi from '../src/artifacts/contracts/Vote.sol/Vote.json';

import minting from './minting.gif';

const hasvote = false;

///todo
// approve entire balance of user


/////////////////////////////////////////
// vars that need altering for deployment
/////////////////////////////////////////
// mint passes generated for premint phase
var track = 0;
const mintPasses = {
  '0': {
    mintPass: {
      message: '0x0000000000000000000000000000000000000000',
      r: '0x0000000000000000000000000000000000000000000000000000000000000000',
      s: '0x0000000000000000000000000000000000000000000000000000000000000000',
      v: 0
    }
  }, 
};







var pixelContractAddress;
var contractAddress;
const voteAddress = "0x0000000000000000000000000000000000000000"; 

const targ = "main";
var targetChainId;
var chainParams;
if(targ == "private"){
    contractAddress = "0x0000000000000000000000000000000000000000";//private
    pixelContractAddress = "0x0000000000000000000000000000000000000000";
   targetChainId = 0;
   chainParams = {
                        chainId: "0x00",
                        rpcUrls: ["https://rpc"],
                        chainName: "main net",
                        nativeCurrency: {
                            name: "",
                            symbol: "",
                            decimals: 18
                        }
                      };
}else if (targ =="test"){
    contractAddress = "0x0000000000000000000000000000000000000000";//test
    pixelContractAddress = "0x0000000000000000000000000000000000000000";
   targetChainId = 0;
   chainParams = {
                        chainId: "0x00",
                        rpcUrls: ["https://rpc"],
                        chainName: "main net",
                        nativeCurrency: {
                            name: "",
                            symbol: "",
                            decimals: 18
                        }
                      };

}else{
    contractAddress = "0x0000000000000000000000000000000000000000";//main
    pixelContractAddress = "0x0000000000000000000000000000000000000000";
   targetChainId = 0;
   chainParams = {
                        chainId: "0x00",
                        rpcUrls: ["https://rpc"],
                        chainName: "main net",
                        nativeCurrency: {
                            name: "",
                            symbol: "",
                            decimals: 18
                        }
                      };                    
}
var maxPerWallet = 1; // updated in getOwned
///////////////////////////////////////////////////////////////////////const




export default function App() {
  
  const [errorMsg, setErrorMsg] = useState("");
  const [voteMsg, setVoteMsg] = useState("");
  const [hideButton, toggleButton] = useState(false);

  /*image placeholder for owned NFT / title to show supply*/
  const [imageurl, setImageURL] = useState("");
  const [visibleTitle, setVisibleTitle] = useState("");
  const [nftName, setNftName] = useState("");
  const [price, setPrice] = useState("");

  const [voteAvailable, setVoteAvailable] = useState(false);

  const [images, setImageURLs] = useState([]);
  const [names, setNames] = useState([]);
  /*store user public key*/
  const [currentAccount, setCurrentAccount] = useState("");

  //UI for #
  const [mintAmount, setMintAmount] = useState(1);
  const handleMintAmount = event => {
    if(parseInt(event.target.value) > maxPerWallet){
      setMintAmount(maxPerWallet);
      event.target.value = maxPerWallet;
    }else if(parseInt(event.target.value) <= 0){
      setMintAmount(1);
      event.target.value = 1;
    }else
      setMintAmount(parseInt(event.target.value));
   
  };

  const contractABI =  abi.abi;
  const voteabi =  vabi.abi;

  
  /* check for MMask and correct Chain*/
  const checkIfWalletIsConnected = async () => {
    try {
      const { ethereum } = window;
      if (!ethereum) {
        setErrorMsg("error : MetaMask is required to mint Sheep");
        console.log("make sure you have metamask");
        toggleButton(false);
        
      } else {
        console.log("allright");
        setErrorMsg("");
        toggleButton(true);
      }
      /*check authorization to access user wallet*/
      const accounts = await ethereum.request({method: "eth_accounts"});
      if (accounts.length !== 0) {
        const account = accounts[0];
        console.log("Connected account:", account);
        setCurrentAccount(account)
        const chainIda = await ethereum.request({method: "eth_chainId"})
        console.log("Current Network:", chainIda)
        if ( parseInt(chainIda,16) == targetChainId){
          console.log("Correct Chain"); // show button
          setErrorMsg("");
          toggleButton(true);
        }else{
          setErrorMsg("error : Please select the Mainnet as your current wallet chain");
          console.log("Incorrect Chain");
           toggleButton(false);
          //button to activate this
          
          const chainIdb = await ethereum.request({ //////////////////MUST UPDATE FOR PRODUCTION
            method: "wallet_addEthereumChain",
            params: [chainParams]
          })

          checkIfWalletIsConnected(); //maybe page refresh isntead?
          
        }
        // show last text on UI everytime <---what?
        const callgetSupply = getSupply();
      } else {
        //setErrorMsg("No authorized account found");
        console.log("No authorized account found")
      } 
    } catch (error) {
      console.log(error);
    }
  }

  
  /* connect to MetaMask */
  const connectWallet = async () => {
    try {
      const { ethereum } = window;

      if (!ethereum) {
        alert("Get MetaMask!");
        return;
      }

      const accounts = await ethereum.request({ method: "eth_requestAccounts" });

      console.log("Connected", accounts[0]);
      setCurrentAccount(accounts[0]);
      const callgetSupply= getSupply();
    } catch (error) {
      console.log(error)
    }
  }

  /* get  stats on how many NFTs are available */
  const getSupply = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const nftContract = new ethers.Contract(contractAddress, contractABI, signer);
        
        // retrieve, calculate supply, and display 
        let result = await nftContract.howMany();
        let cost = await nftContract.cost();
        setPrice(cost / 10**18); 
        const { 0:maxSupply, 1:remaining, 2:burnt} = result;
        let supplyRemaining = remaining-burnt + " out of " + maxSupply + " left to mint";
        console.log("burnt : " + burnt);
        setVisibleTitle(supplyRemaining);
        await supplyRemaining.wait;

        let paused = await nftContract.paused();
        if(paused)
          setErrorMsg("contract paused");

        //determine if wallet has NFTs already to load in NFT on wallet connect
        getOwned();

      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
    }
  }

  const mintOne = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {    
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const nftContract = new ethers.Contract(contractAddress, contractABI, signer);

        setErrorMsg("verifying: ");
        //VERIFICATION B4 MINT/////////////////////////
        console.log("====VERIFICATION===");
        toggleButton(false);

        setErrorMsg("verifying: active contract");
        let paused = await nftContract.paused();
        if(paused) {
          setErrorMsg("error : Contract is Paused, please check discord for more info");
          throw "Contract Paused.";
        }
        
        setImageURL(minting); // loading image
        const checksumAccount = await ethers.utils.getAddress(currentAccount);        
        
        setErrorMsg("verifying: Address");
        // CHECK IF whitelist event
        // CHECK IF Wallet address exists in MINTPASS list
        // Store appropriate mintPass  for submission with Mint request     
        let onlyWhitelisted = await nftContract.onlyWhitelisted();
        if( onlyWhitelisted ){
          if(checksumAccount in mintPasses == false) {
            setErrorMsg("error: Address not approved for Premint");
            throw "No Valid MintPass for this Address.";
          }
          var mintPass = mintPasses[checksumAccount];
        }else{
          var mintPass = mintPasses['0'];
        }
       
        setErrorMsg("verifying: Mint Supply");
        // CHECK # of sheep trying to mint
        let mintMax = await nftContract.maxMintAmount();
        if(mintAmount > mintMax) {
          setErrorMsg("error: You can't mint this many sheep in a single transaction.");
          throw "Minting too many Sheep.";
        }
        console.log("Max Sheep Per Transaction Check : Pass");

        //CHECK Supply left
        let result = await nftContract.howMany();
        const { 0:maxSupply, 1:remaining, 2:burnt} = result;
        let sheepLeft = remaining-burnt;
        if(sheepLeft = mintAmount < 0 ) {
          setErrorMsg("error: Not enough Sheep left.");
          throw "Sheep all gone.";
        }
        console.log("Supply Check : Pass");
    
        // CHECK IF wallet has max allowed sheep
        let maxPerWallet = await nftContract.nftPerAddressLimit();
        let walletOwnedSheep = await nftContract.addressMintedBalance(checksumAccount);
        if( parseInt(walletOwnedSheep) + parseInt(mintAmount) > parseInt(maxPerWallet) ){
          setErrorMsg("error: Max sheep in wallet will be exceeded.");
          throw "Max sheep in wallet will be exceeded."
        }
        console.log("Max Sheep in Wallet Check : Pass");

        setErrorMsg("verifying: Balance");
        //get cost / set price / mint
        let price = await nftContract.cost();
        await price.wait;
        let totalCost = price.mul(mintAmount);
        const overrides = {value: totalCost,}
        let Balance = await provider.getBalance(currentAccount);
        if( Balance < price * mintAmount ){
          setErrorMsg("error: Not enough funds");
          throw "Not enough funds."
        }
        console.log("Balance Check : Pass");
        console.log("===============");

        setErrorMsg("Please Approve Transaction in your Metamask Wallet");
        var mintresult = await nftContract.mint(mintPass.mintPass, mintAmount, overrides);
        setErrorMsg("...minting...");
        console.log("minting nft...")
        await mintresult.wait();
        console.log("Minted --", mintresult.hash);

        toggleButton(true);
        setErrorMsg("Success!");
        //refresh display to show NFT image
        const callgetSupply = getSupply();
      } else {
        console.log("Ethereum object doesn't exist!");
        setImageURL("");
  
        
      }
      

      
    } catch (error) {
      console.log(error)
      setImageURL("");
      toggleButton(true);
      //setErrorMsg("error: " + error);
    }
  }

  //update on metamask changes
  useEffect(() => {
    if(window.ethereum) {
      
      window.ethereum.on('chainChanged', () => {
        window.location.reload();
      })
      window.ethereum.on('accountsChanged', () => {
        window.location.reload();
      })

      window.ethereum.on('requestAccounts', () => {
        window.location.reload();
      })
    
      checkIfWalletIsConnected();
    }
  }, [])


  /* display image of NFT owned by signer -- need to account for multiple */
  const getOwned = async () => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        
        setImageURLs((images) => []);
//BLOCKED PIXELS FOR NOW
        if(targ != 'test' && false){
          const pixelContract = new ethers.Contract(pixelContractAddress, contractABI, signer);      
          const pixelResult = await pixelContract.walletOfOwner(signer.getAddress());
          console.log(pixelResult);
          for(var i=0; i<pixelResult.length; i++){
            if(pixelResult[i]){    
            console.log(pixelResult[i].toNumber())     ;
              // returns metadata json of NFT and sets imageurl state
              const meta = await getMeta('pixel', pixelResult[i].toNumber());
              await meta.wait;
              console.log(meta);
              setImageURLs((images) =>[...images, meta.image]);
              setNames((names) =>[...names, meta.name]);
            }
          }
        }

        const nftContract = new ethers.Contract(contractAddress, contractABI, signer);        
        // returns tokenIDs of owned NFT
        const result = await nftContract.walletOfOwner(signer.getAddress());
        maxPerWallet = await nftContract.nftPerAddressLimit();
        for(var i=0; i<result.length; i++){
          if(result[i]){         
            // returns metadata json of NFT and sets imageurl state
            const meta = await getMeta('golden', result[i].toNumber());
            await meta.wait;
            setImageURLs((images) =>[...images, meta.image]);
            setNames((names) =>[...names, meta.name]);
          }
        }


        isVote();
        //if(result.length > 0 && hasvote){
        if(result.length > 0 && hasvote){
          setVoteAvailable(true);
        }else{
          setVoteAvailable(false);
        }
        console.log('v');
        
        //remove mint button if max owned
        if(result.length >= maxPerWallet){
          toggleButton(false);
        }
        
      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot retrieve wallet info");
      }
    } catch (error) {
      console.log(error)
    }
    
  }


  /* returns metadata json from tokenID */
  const getMeta = async (sheepType, i) => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();

        if(sheepType == 'golden'){
          const nftContract = new ethers.Contract(contractAddress, contractABI, signer);

          // gets metadata from ARWEAVE and reads JSON
          const uri = await nftContract.tokenURI(i);
          const m = fetch(uri,{         
          })
          .then(function(response){
            return response.json();
          })
          .then(function(meta) {
            return meta;  
            
          });  
          return m;  
          
        }else if (sheepType == 'pixel' && targ != 'test'){
          const pixelContract = new ethers.Contract(pixelContractAddress, contractABI, signer);

          // gets metadata from IPFS and reads JSON
          const uri = await pixelContract.tokenURI(i);
          const m = fetch(uri,{  
            headers : { 
              'Content-Type': 'application/json',
              'Accept': 'application/json'
             }       
          })
          .then(function(response){
            return response.json();
          })
          .then(function(meta) {
            return meta;  
            
          });    
          return m;
        }

        
              
      } else {
        console.log("Ethereum object doesn't exist!");
        setErrorMsg("Cannot retrieve Metadata");
      }
    } catch (error) {
      console.log(error)
      setErrorMsg("Cannot retrieve Metadata");
    }
    
  }
  /*------------------VOTE-------------*/



const isVote = async() =>{
   try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const voteContract = new ethers.Contract(voteAddress, voteabi, signer);
               
        let hasvote = await voteContract.activeVote();
        console.log("hasvote: " + hasvote);        
        setVoteAvailable(hasvote);
        let pipnum = await voteContract.IPNum();
        console.log("ipnum: " + pipnum); 

        //let result = await voteContract.newVote();
        //console.log(result);

        //let vresult = await voteContract.toggleVote(false);
        //console.log(vresult);

        //let ipnum = await voteContract.IPNum();
        //console.log("ipnum: " + ipnum); 
/*
       let jv = await voteContract.numVotesCast();
        console.log("jv: " + jv);        
       

        let r = await voteContract.getVoteResult(2);
        const { 0:addresses, 1:tokenIds, 2:votes} = r;
        console.log(addresses);
        console.log(votes);
*/
      } else {
        console.log("Ethereum object doesn't exist!");
        //setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
      setVoteMsg("Error Voting: Do you have sheep that are eligible to vote?");
    }
  }



function vote(){}



  const castVote = async (myVote) => {
    try {
      const { ethereum } = window;
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const voteContract = new ethers.Contract(voteAddress, voteabi, signer);

        setVoteMsg("Please Approve Transaction in your MM Wallet");

       
       if(myVote == "x"){

          let result = await voteContract.IPNum();
          console.log(result);
/*
          let av = await voteContract.activeVote();
          console.log(av);

          let r = await voteContract.getVoteResult(2);
          const { 0:addresses, 1:tokenIds, 2:votes} = r;
          console.log(addresses);
          console.log(votes);
*/
          //let nresult = await voteContract.newVote();
          //console.log(nresult);
        }else{
          console.log(myVote);
          let result = await voteContract.castVote(myVote);
          console.log(result);

          let vcnt = result / 10**18;

          setVoteMsg("Vote cast. Your baahh has been herd");
        }
         
      } else {
        console.log("Ethereum object doesn't exist!");
        //setErrorMsg("Cannot connect to Contract");
      }
    } catch (error) {
      console.log(error)
      setVoteMsg("Error Voting: Do you have sheep that are eligible to vote?");
    }
  }

  //////////////////////////////////
  return (
    <>
    <div className="mainContainer">
      <div className="dataContainer">
        <div className="cms"><span>SHEEP!</span></div>
        {currentAccount && (
          <div className="dataTop">
            {visibleTitle && (
              <>
              <h2>SHEEP : {visibleTitle}!</h2>
              <h2>current price : {price} </h2>
              </>
            )}

            <div className="dataTop-action">
            

              {hideButton &&(
                <>
                    

                    <button className="mintButton" onClick={()  => mintOne()}>mint sheep</button>
                    #<input placeholder = "1" onChange={handleMintAmount}
                          onKeyPress={(event) => {
                            if (!/[0-9]/.test(event.key)) {
                              event.preventDefault();
                            }
                          }}
                    />
                </>
              )}
              
            </div>
          </div>
        )}
        <div className="error">
          {errorMsg && (
            <h4>{errorMsg}</h4>
          )}
        </div>
        {!currentAccount && (
          <div className="dataBottom">
            <button className="waveButton" onClick={connectWallet}>Connect Wallet</button>
            <a href="https://metamask.io/download/" >don't have a metamask wallet? click here</a>
          </div> 
        )}
        {currentAccount && (
          <div className='nftDisplay'>

              {images.map((image,index)=> (
                
                  <div className='nft' key={index}>
                  <>
                    <div className='token' >
                      <img  src={image} />
                       
                    </div>
                    <div className="nftname" >
                      {names[index]}
                    </div>
                    </>
                  </div>
                
            

              ))}

               
              
          </div>
        )}
        {voteAvailable && (
                <>   
                  <div className='votearea'>        
                    <div className="error">
                        <h4>CMSIP-4 <a target="_blank" href="https://discord.com/channels/948244056209768458/1006996591036608512/1011381014381207604">details</a></h4>
                    </div>     
                    <button className="voteButton" onClick={()  => castVote(true)}>YES!</button>
                    <button className="voteButton" onClick={()  => castVote(false)}>NO!</button>
                    {voteMsg &&(
                      <h4>{voteMsg}</h4>
                      )}
                  </div>
                </>
              )}
      </div>
    </div>
    <div className="bottom">
      
      {contractAddress && (
        <h3>contract : {contractAddress}
        </h3>
      )}
    </div>   
  </>
  );
}