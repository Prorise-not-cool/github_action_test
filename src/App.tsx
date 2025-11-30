import { VERSION } from "./version"

export default function App() {
  const handleClick = () => {
    alert("Button clicked")
  }
  return <div>
    <p>Version: {VERSION}</p>
    <button onClick={handleClick}>Click me</button>
  </div>
}