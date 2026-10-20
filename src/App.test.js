import { render, screen } from "@testing-library/react";
import App from "./App";

jest.mock("./pages/index", () => ({
  ChannelDetails: () => <div>Channel details page</div>,
  Feed: () => <div>Feed page</div>,
  SearchFeed: () => <div>Search results page</div>,
  Sidebar: () => <nav>Sidebar</nav>,
  VideoDetails: () => <div>Video details page</div>,
}));

test("renders the home feed", () => {
  render(<App />);

  expect(screen.getByText("Sidebar")).toBeInTheDocument();
  expect(screen.getByText("Feed page")).toBeInTheDocument();
});
