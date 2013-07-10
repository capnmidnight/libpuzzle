using System;
using System.Collections.Generic;
using System.Text;
using PuzzleFramework;

namespace Puzzles
{
    public class TetrisGame : Puzzle
    {
        private static Puzzle[] pieces;
        static Random rand;
        static TetrisGame()
        {
            pieces = new Puzzle[7];
            pieces[0] = new Puzzle(new int[,] { { 1, 1, 1, 1 } });
            pieces[1] = new Puzzle(new int[,] { { 2, 2 },
                                                { 2, 2 } });
            pieces[2] = new Puzzle(new int[,] { { -1, 3, -1 }, 
                                                {  3, 3,  3 } });
            pieces[3] = new Puzzle(new int[,] { { 4, 4, -1 }, { -1, 4, 4 } });
            pieces[4] = new Puzzle(new int[,] { { -1, 5, 5 }, { 5, 5, -1 } });
            pieces[5] = new Puzzle(new int[,] { { 6, -1, -1 }, { 6, 6, 6 } });
            pieces[6] = new Puzzle(new int[,] { { -1, -1, 7 }, { 7, 7, 7 } });

            rand = new Random();
        }
        Puzzle next, current;
        int cursorX, cursorY, score;
        bool gameOver, isLeftDown, isRightDown, isUpDown, isDownDown;
        int millisPerDrop, lessMillisPerLine, millisPerMove, millisPerFlip, millisPerAdvance;
        double sinceLastMove, sinceLastDrop, sinceLastFlip, sinceLastAdvance, sincePieceEntered;

        public void Reset()
        {
            millisPerDrop = 500;
            millisPerFlip = 250;
            millisPerMove = 200;
            millisPerAdvance = 25;
            lessMillisPerLine = 10;
            
            current = pieces[rand.Next(pieces.Length)];
            next = pieces[rand.Next(pieces.Length)];
            cursorX = this.Width / 2;
            cursorY = 0;
            score = 0;
            gameOver = false;
            sinceLastMove = sinceLastDrop = sinceLastFlip = sinceLastAdvance = sincePieceEntered = 0.0;
        }

        public TetrisGame(int width, int height)
            : base(width, height)
        {
            Reset();
        }
        public TetrisGame(int[,] grid)
            : base(grid)
        {
            Reset();
        }

        private void MoveLeft()
        {
            if (this.IsInBounds(cursorX - 1, cursorY, current)
                        && this.IsEmpty(cursorX - 1, cursorY, current))
                cursorX--;
        }

        private void MoveRight()
        {
            if (this.IsInBounds(cursorX + 1, cursorY, current)
                        && this.IsEmpty(cursorX + 1, cursorY, current))
                cursorX++;
        }

        public bool Update(TimeSpan sinceLastDraw)
        {
            if (isLeftDown || isRightDown)
            {
                sinceLastMove += sinceLastDraw.TotalMilliseconds;
                if (sinceLastMove >= millisPerMove)
                {
                    sinceLastMove = 0.0;
                    if (isLeftDown)
                        MoveLeft();

                    if (isRightDown)
                        MoveRight();
                }
            }
            else
                sinceLastMove = 0.0;


            if (isUpDown)
            {
                sinceLastFlip += sinceLastDraw.TotalMilliseconds;
                if (sinceLastFlip >= millisPerFlip)
                {
                    sinceLastFlip = 0.0;
                    Puzzle pre = current.Rotate(Puzzle.Clockwise);
                    this.PlayFlip();
                    if (isUpDown && this.IsInBounds(cursorX, cursorY, pre)
                        && this.IsEmpty(cursorX, cursorY, pre))
                        current = pre;
                }
            }
            else
                sinceLastFlip = 0.0;

            if (isDownDown && sincePieceEntered >= 500.0)
            {
                sinceLastAdvance += sinceLastDraw.TotalMilliseconds;
                if (sinceLastAdvance >= millisPerAdvance)
                {
                    sinceLastAdvance = 0.0;
                    if (this.IsInBounds(cursorX, cursorY + 1, current)
                            && this.IsEmpty(cursorX, cursorY + 1, current))
                        cursorY++;
                }
            }
            else
                sinceLastAdvance = 0.0;

            sinceLastDrop += sinceLastDraw.TotalMilliseconds;
            sincePieceEntered += sinceLastDraw.TotalMilliseconds;

            if (sinceLastDrop >= millisPerDrop)
            {
                sinceLastDrop = 0.0;
                if (!this.IsEmpty(Puzzle.RowOrder, 0))
                {
                    gameOver = true;
                }
                if (!gameOver)
                {
                    if (this.IsEmpty(cursorX, cursorY + 1, current)
                        && this.IsInBounds(cursorX, cursorY + 1, current))
                    {
                        cursorY++;
                    }
                    else
                    {
                        this.Fill(cursorX, cursorY, current);
                        this.PlayThump();
                        current = next;
                        next = pieces[rand.Next(pieces.Length)];
                        sincePieceEntered = 0.0;
                        cursorX = this.Width / 2;
                        cursorY = 0;
                    }
                    int clearCount = 0;
                    for (int y = 0; y < this.Height; ++y)
                    {
                        if (this.IsFull(Puzzle.RowOrder, y))
                        {
                            this.TetrisClearRow(y);
                            y--; //rewind, because TetrisClearRow changes the layout of the board
                            clearCount++;
                        }
                    }
                    if (clearCount > 0)
                    {
                        this.PlayLineClear(clearCount);
                        score += clearCount * clearCount * 100;
                        millisPerDrop -= lessMillisPerLine;
                    }
                }
                return true;
            }
            return false;
        }
        public void Left_Depress()
        {
            isLeftDown = true;
            MoveLeft();
        }
        public void Left_Release()
        {
            isLeftDown = false;
        }
        public void Right_Depress()
        {
            isRightDown = true;
            MoveRight();
        }
        public void Right_Release()
        {
            isRightDown = false;
        }
        public void Up_Depress()
        {
            if (!isUpDown)
                sinceLastFlip = millisPerFlip;
            isUpDown = true;
        }
        public void Up_Release()
        {
            isUpDown = false;
        }

        public void Down_Depress()
        {
            isDownDown = true;
        }
        public void Down_Release()
        {
            isDownDown = false;
        }
        public Puzzle Next
        {
            get
            {
                return this.next;
            }
        }
        public Puzzle Current
        {
            get
            {
                return this.current;
            }
        }
        public int CursorX
        {
            get
            {
                return this.cursorX;
            }
        }
        public int CursorY
        {
            get
            {
                return this.cursorY;
            }
        }

        public int Score
        {
            get
            {
                return this.score;
            }
        }

        public bool GameOver
        {
            get
            {
                return this.gameOver;
            }
        }

        public void TetrisClearRow(int row)
        {
            if (this.IsInBounds(0, row))
                for (int x = 0; x < this.Width; ++x)
                {
                    for (int y = row; y > 0; --y)
                        this[x, y] = this[x, y - 1];
                    this[x, 0] = -1;
                }
        }

        protected virtual void PlayThump()
        {
        }

        protected virtual void PlayLineClear(int numLines)
        {
        }

        protected virtual void PlayFlip()
        {
        }
    }
}