#lang racket

(define EMPTY_TILE -1)
(define ROW_ORDER #t)
(define COLUMN_ORDER (not ROW_ORDER))
(define CLOCKWISE #t)
(define COUNTERCLOCKWISE (not CLOCKWISE))

;; A physical representation of a puzzle as a 2D array of tile pieces. 
;; The grid can be manipulated in various ways to help facilitate rapid
;; puzzle creations.
(define positive/c (and/c number? positive?))
(define/contract puzzle%
  (class/c (field [width positive/c]
                  [height positive/c]))
  (class object% 
    (init-field width
                height)
    (init [source-grid null])
    (super-new)
    
    (field [grid (if (not (null? source-grid))
                     (begin
                       (set! height (vector-length source-grid))
                       (set! width (vector-length (vector-ref source-grid 0)))
                       (for/vector ([row source-grid]) 
                         (for/vector ([x row]) x)))
                     (for/vector ([y (in-range height)])
                       (make-vector width EMPTY_TILE)))])
  
    ;; Determine if a point or rectangle is within the bounds of the board
    (define/public (in-bounds? x y [w 0] [h 0])
      (and (<= 0 x (sub1 width))
           (<= 0 (+ x w) (sub1 width))
           (<= 0 y (sub1 height))
           (<= 0 (+ y h) (sub1 height))))
    
    ;; Determine if a shape is completely contained within the board
    (define/public (shape-in-bounds? x y v-shape)
      (and (not (null? v-shape))
           (vector? v-shape)
           (andmap vector? v-shape)
           (for/and ([row v-shape]
                     [dy (in-range (vector-length v-shape))])
             (for/and ([cell row]
                       [dx (in-range (vector-length row))])
               (or (equal? EMPTY_TILE cell)
                   (in-bounds? (+ x dx) (+ y dy)))))))
    
    ;; Determine if a puzzle piece is completely contained within the board
    (define/public (puzzle%-in-bounds? x y shape)
        (and (not (null? shape))
             (shape-in-bounds? (get-field grid shape))))
    
    ;; Gets a specific value at a given point
    (define/public (get x y)
      (when (in-bounds? x y)
        (vector-ref (vector-ref grid y) x)))
    
    ;; Sets a specific value at a given point
    (define/public (set-tile! x y v)
      (when (in-bounds? x y)
        (vector-set! (vector-ref grid y) x v)))
    
    ;; Clear areas of the puzzle board
    (define/public (clear-rectangle #:x [x 0] #:y [y 0] #:width [wid width] #:height [hi height])
      (let ([w wid]
            [h hi])
        (when (< w 0) (set! w (sub1 width)))
        (when (< h 0) (set! h (sub1 height)))
        (for ([dy (in-range h)])
          (for ([dx (in-range w)])
            (set-tile! (+ x dx) (+ y dy) EMPTY_TILE)))))
    
    (define/public (clear-point x y)
      (clear-rectangle #:x x #:y y #:width 1 #:height 1))
    
    (define/public (clear-row y)
      (clear-rectangle #:y y #:height 1))
    
    (define/public (clear-column x)
      (clear-rectangle #:x x #:width -1))
    
    (define/public (clear)
      (clear-rectangle))
    ))

(define (puzzle%->string puz)
  (let ([out (open-output-string)]
        [shape (get-field grid puz)])
    (for ([row shape])
      (displayln row out))
    (get-output-string out)))

(let ([p (new puzzle% [width 5] [height 4])])
  (send p set-tile! 2 2 2)
  (displayln (puzzle%->string p))
  (send p clear)
  (displayln (puzzle%->string p)))
#|
        /// <summary>
        /// Batch clear specific points on the grid
        /// </summary>
        /// <param name="mask">a 2D array of flags marking points that should be cleared. The array should be as
        /// large as the puzzle grid</param>
        public void Clear(int[,] mask)
        {
            if (mask != null && mask.GetLength(0) == this.Height && mask.GetLength(1) == this.Width)
                for (int y = 0; y < this.Height; ++y)
                    for (int x = 0; x < this.Width; ++x)
                        if (mask[y, x] != Puzzle.EmptyTile)
                            this.grid[y, x] = Puzzle.EmptyTile;
        }

        /// <summary>
        /// Clear an irregularly shaped area of the board
        /// </summary>
        /// <param name="left"></param>
        /// <param name="top"></param>
        /// <param name="shape">a 2D array of flags marking points that should be cleared.</param>
        public void Clear(int left, int top, int[,] shape)
        {
            if (shape != null)
                for (int y = top; y < shape.GetLength(0) + top; ++y)
                    if (y >= 0 && y < this.Height)
                        for (int x = left; x < shape.GetLength(1) + left; ++x)
                            if (x >= 0 && x < this.Width && shape[y - top, x - left] != Puzzle.EmptyTile)
                                this.grid[y, x] = Puzzle.EmptyTile;
        }

        public void Clear(int left, int top, Puzzle shape)
        {
            if (shape != null)
                this.Clear(left, top, shape.grid);
        }

        /// <summary>
        /// Fill the entire puzzle grid with a single value
        /// </summary>
        /// <param name="value"></param>
        public void Fill(int value)
        {
            this.Fill(0, 0, this.Width, this.Height, value);
        }

        /// <summary>
        /// Fill a row or column with a single value
        /// </summary>
        /// <param name="order">Puzzle.RowOrder to fill a row, Puzzle.ColumnOrder to fill a column</param>
        /// <param name="ordinal">the row or column index to fill</param>
        /// <param name="value"></param>
        public void Fill(bool order, int ordinal, int value)
        {
            if (order == Puzzle.RowOrder)
                this.Fill(0, ordinal, this.Width, 1, value);
            else
                this.Fill(ordinal, 0, 1, this.Height, value);
        }

        /// <summary>
        /// Fill a rectangular portion of the board
        /// </summary>
        /// <param name="left"></param>
        /// <param name="top"></param>
        /// <param name="width"></param>
        /// <param name="height"></param>
        /// <param name="value"></param>
        public void Fill(int left, int top, int width, int height, int value)
        {
            for (int y = top; y < top + height && y < this.Height; ++y)
                if (y >= 0)
                    for (int x = left; x < left + width && x < this.Width; ++x)
                        if (x >= 0)
                            this.grid[y, x] = value;
        }

        /// <summary>
        /// Use a pseudorandom number generator to fill the entire board
        /// </summary>
        /// <param name="prand"></param>
        public void Fill(Random prand)
        {
            if (prand != null)
                for (int y = 0; y < this.Height; ++y)
                    for (int x = 0; x < this.Width; ++x)
                        this.grid[y, x] = prand.Next();
        }

        /// <summary>
        /// Use a pseudorandom number generator to fill the entire board
        /// </summary>
        public void Fill()
        {
            this.Fill(new Random());
        }

        /// <summary>
        /// Copy a puzzle piece on top of the current puzzle at a specific location.
        /// </summary>
        /// <param name="left"></param>
        /// <param name="top"></param>
        /// <param name="piece"></param>
        public void Fill(int left, int top, Puzzle piece)
        {
            if (piece != null)
                this.Fill(left, top, piece.grid);
        }

        /// <summary>
        /// Fill a specific area with a shape. Ignores empty tiles in the shape.
        /// </summary>
        /// <param name="left"></param>
        /// <param name="top"></param>
        /// <param name="shape"></param>
        public void Fill(int left, int top, int[,] shape)
        {
            if (shape != null)
                for (int y = top; y < top + shape.GetLength(0) && y < this.Height; ++y)
                    if (y >= 0)
                        for (int x = left; x < left + shape.GetLength(1) && x < this.Width; ++x)
                            if (x >= 0 && shape[y - top, x - left] != Puzzle.EmptyTile)
                                this.grid[y, x] = shape[y - top, x - left];
        }

        /// <summary>
        /// Make tiles above empty spots shift down into the empty spot, leaving an empty spot behind them.
        /// This is a modification of Insertion Sort, and is an O(n^3) operation.
        /// </summary>
        public void ShiftColumnsDown()
        {
            for (int x = 0; x < this.Width; ++x)
                for (int y = this.Height - 1; y > 0; --y)
                    for (int y2 = y - 1; y2 >= 0; --y2)
                        if (this.grid[y, x] == Puzzle.EmptyTile)
                        {
                            this.grid[y, x] = this.grid[y2, x];
                            this.grid[y2, x] = Puzzle.EmptyTile;
                        }
        }


        /// <summary>
        /// Make tiles below empty spots shift up into the empty spot, leaving an empty spot behind them.
        /// This is a modification of Insertion Sort, and is an O(n^3) operation.
        /// </summary>
        public void ShiftColumnsUp()
        {
            for (int x = 0; x < this.Width; ++x)
                for (int y = 0; y < this.Height - 1; ++y)
                    for (int y2 = y + 1; y2 < this.Height; ++y2)
                        if (this.grid[y, x] == Puzzle.EmptyTile)
                        {
                            this.grid[y, x] = this.grid[y2, x];
                            this.grid[y2, x] = Puzzle.EmptyTile;
                        }
        }

        /// <summary>
        /// Make tiles to the right empty spots shift left into the empty spot, leaving an empty spot behind them.
        /// This is a modification of Insertion Sort, and is an O(n^3) operation.
        /// </summary>
        public void ShiftColumnsLeft()
        {
            for (int y = 0; y < this.Height; ++y)
                for (int x = 0; x < this.Width - 1; ++x)
                    for (int x2 = x + 1; x2 < this.Width; ++x2)
                        if (this.grid[y, x] == Puzzle.EmptyTile)
                        {
                            this.grid[y, x] = this.grid[y, x2];
                            this.grid[y, x2] = Puzzle.EmptyTile;
                        }
        }

        /// <summary>
        /// Make tiles to the left empty spots shift right into the empty spot, leaving an empty spot behind them.
        /// This is a modification of Insertion Sort, and is an O(n^3) operation.
        /// </summary>
        public void ShiftColumnsRight()
        {
            for (int y = 0; y < this.Height; ++y)
                for (int x = this.Width - 1; x > 0; --x)
                    for (int x2 = x - 1; x2 >= 0; --x2)
                        if (this.grid[y, x] == Puzzle.EmptyTile)
                        {
                            this.grid[y, x] = this.grid[y, x2];
                            this.grid[y, x2] = Puzzle.EmptyTile;
                        }
        }

        

        /// <summary>
        /// Compares two puzzles to see if they match.
        /// </summary>
        /// <param name="p"></param>
        /// <returns>+1 if the dimensions do not match
        /// -1 if at least one of the points do not match
        /// 0 if the puzzles are equivalent</returns>
        public int CompareTo(Puzzle p)
        {
            if (this.Width == p.Width && this.Height == p.Height)
            {
                for (int y = 0; y < this.Height; ++y)
                    for (int x = 0; x < this.Width; ++x)
                        if (this[x, y] != p[x, y])
                            return -1;
                return 0;
            }
            return +1;
        }

        /// <summary>
        /// Compare two puzzles to see if they match element-for-element
        /// </summary>
        /// <param name="obj"></param>
        /// <returns></returns>
        public override bool Equals(object obj)
        {
            if (obj is Puzzle)
                return this.CompareTo(obj as Puzzle) == 0;
            return false;
        }

        /// <summary>
        /// A recommended override if one overrides the Equals method
        /// </summary>
        /// <returns></returns>
        public override int GetHashCode()
        {
            return this.grid.GetHashCode();
        }

        /// <summary>
        /// Swap two specific points on the puzzle
        /// </summary>
        /// <param name="x1"></param>
        /// <param name="y1"></param>
        /// <param name="x2"></param>
        /// <param name="y2"></param>
        public void Swap(int x1, int y1, int x2, int y2)
        {
            this.Swap(x1, y1, x2, y2, 1, 1);
        }

        /// <summary>
        /// Swap two rows or two columns
        /// </summary>
        /// <param name="order"></param>
        /// <param name="ordinal1"></param>
        /// <param name="ordinal2"></param>
        public void Swap(bool order, int ordinal1, int ordinal2)
        {
            if (order == Puzzle.RowOrder)
                this.Swap(0, ordinal1, 0, ordinal2, this.Width, 1);
            else
                this.Swap(ordinal1, 0, ordinal2, 0, 1, this.Height);
        }

        /// <summary>
        /// Swap two rectangular areas that have the same dimensions but do not overlap
        /// </summary>
        /// <param name="x1"></param>
        /// <param name="y1"></param>
        /// <param name="x2"></param>
        /// <param name="y2"></param>
        /// <param name="width"></param>
        /// <param name="height"></param>
        public void Swap(int x1, int y1, int x2, int y2, int width, int height)
        {
            int temp;
            if (this.IsInBounds(x1, y1, width, height) && this.IsInBounds(x2, y2, width, height)
                && !RectsIntersect(x1, y1, x2, y2, width, height))
                for (int y = 0; y < height; ++y)
                    for (int x = 0; x < width; ++x)
                    {
                        temp = this.grid[y1 + y, x1 + x];
                        this.grid[y1 + y, x1 + x] = this.grid[y2 + y, x2 + x];
                        this.grid[y2 + y, x2 + x] = temp;
                    }
        }

        /// <summary>
        /// Check if two rectangles, of the same size in different locations, overlap each other.
        /// </summary>
        /// <param name="x1"></param>
        /// <param name="y1"></param>
        /// <param name="x2"></param>
        /// <param name="y2"></param>
        /// <param name="width"></param>
        /// <param name="height"></param>
        /// <returns></returns>
        public static bool RectsIntersect(int x1, int y1, int x2, int y2, int width, int height)
        {
            System.Drawing.Rectangle a, b;
            a = new System.Drawing.Rectangle(x1, y1, width, height);
            b = new System.Drawing.Rectangle(x2, y2, width, height);
            return a.IntersectsWith(b);
        }

        /// <summary>
        /// Rotate the puzzle by 90 degrees in either a clockwise or counterclockwise direction
        /// </summary>
        /// <param name="direction"></param>
        /// <returns>A new puzzle that represents the rotated puzzle</returns>
        public Puzzle Rotate(bool direction)
        {
            Puzzle q = new Puzzle(this.Height, this.Width);

            if (direction == Puzzle.Clockwise)
                for (int y = 0; y < this.Height; ++y)
                    for (int x = 0; x < this.Width; ++x)
                        q[q.Width - y - 1, x] = this[x, y];
            else
                for (int y = 0; y < this.Height; ++y)
                    for (int x = 0; x < this.Width; ++x)
                        q[y, q.Height - x - 1] = this[x, y];
            return q;
        }

        /// <summary>
        /// Creates a copy of the current puzzle
        /// </summary>
        /// <returns></returns>
        public Puzzle Duplicate()
        {
            return new Puzzle(this.grid);
        }

        /// <summary>
        /// Check to see if the board is full
        /// </summary>
        /// <returns></returns>
        public bool IsFull()
        {
            return this.IsFull(0, 0, this.Width, this.Height);
        }

        /// <summary>
        /// Check to see if a row or column is full
        /// </summary>
        /// <param name="order"></param>
        /// <param name="ordinal"></param>
        /// <returns></returns>
        public bool IsFull(bool order, int ordinal)
        {
            if (order == Puzzle.RowOrder)
                return this.IsFull(0, ordinal, this.Width, 1);
            else
                return this.IsFull(ordinal, 0, 1, this.Height);
        }

        /// <summary>
        /// Check to see if a rectangular area is full
        /// </summary>
        /// <param name="x"></param>
        /// <param name="y"></param>
        /// <param name="width"></param>
        /// <param name="height"></param>
        /// <returns></returns>
        public bool IsFull(int x, int y, int width, int height)
        {
            for (int dy = 0; dy < height; ++dy)
                for (int dx = 0; dx < width; ++dx)
                    if (this[x + dx, y + dy] == Puzzle.EmptyTile)
                        return false;
            return true;
        }

        /// <summary>
        /// Check to see if a mask shape is full
        /// </summary>
        /// <param name="x"></param>
        /// <param name="y"></param>
        /// <param name="shape"></param>
        /// <returns></returns>
        public bool IsFull(int x, int y, int[,] shape)
        {
            if (shape == null || shape.Length == 0)
                return false;
            for (int dy = 0; dy < shape.GetLength(0); ++dy)
                for (int dx = 0; dx < shape.GetLength(1); ++dx)
                    if (shape[dy, dx] != Puzzle.EmptyTile && this[x + dx, y + dy] == Puzzle.EmptyTile)
                        return false;
            return true;
        }

        /// <summary>
        /// Check to see if a puzzle piece shape is full
        /// </summary>
        /// <param name="x"></param>
        /// <param name="y"></param>
        /// <param name="shape"></param>
        /// <returns></returns>
        public bool IsFull(int x, int y, Puzzle shape)
        {
            return shape != null && this.IsFull(x, y, shape.grid);
        }

        public bool IsEmpty()
        {
            return this.IsEmpty(0, 0, this.Width, this.Height);
        }

        public bool IsEmpty(bool order, int ordinal)
        {
            if (order == Puzzle.RowOrder)
                return this.IsEmpty(0, ordinal, this.Width, 1);
            else
                return this.IsEmpty(ordinal, 0, 1, this.Height);
        }

        public bool IsEmpty(int x, int y, int width, int height)
        {
            for (int dy = 0; dy < height; ++dy)
                for (int dx = 0; dx < width; ++dx)
                    if (this[x + dx, y + dy] != Puzzle.EmptyTile)
                        return false;
            return true;
        }

        public bool IsEmpty(int x, int y, int[,] shape)
        {
            if (shape == null || shape.Length == 0)
                return false;
            for (int dy = 0; dy < shape.GetLength(0); ++dy)
                for (int dx = 0; dx < shape.GetLength(1); ++dx)
                    if (shape[dy, dx] != Puzzle.EmptyTile && this[x + dx, y + dy] != Puzzle.EmptyTile)
                        return false;
            return true;
        }

        public bool IsEmpty(int x, int y, Puzzle shape)
        {
            return shape != null && this.IsEmpty(x, y, shape.grid);
        }
    }
}
|#